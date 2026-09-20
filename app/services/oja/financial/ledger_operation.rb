module Oja
  module Financial
    class LedgerOperation
      Result = Struct.new(:applied, :reason, :entry, keyword_init: true)
      DELTAS = {
        "consume" => { reserved_minor: -1, consumed_minor: 1 },
        "release" => { reserved_minor: -1, released_minor: 1 },
        "reverse" => { consumed_minor: -1, reversed_minor: 1 }
      }.freeze

      def self.call(allocation:, entry_type:, amount_minor:, idempotency_key:, correlation_id:, metadata: {})
        new(allocation:, entry_type:, amount_minor:, idempotency_key:, correlation_id:, metadata:).call
      end

      def initialize(allocation:, entry_type:, amount_minor:, idempotency_key:, correlation_id:, metadata:)
        @allocation, @entry_type, @amount = allocation, entry_type.to_s, Integer(amount_minor)
        @idempotency_key, @correlation_id, @metadata = idempotency_key, correlation_id, metadata
      end

      def call
        Oja::Idempotency.validate!(@idempotency_key)
        raise ArgumentError, "correlation_id is required" if @correlation_id.to_s.empty?
        raise ArgumentError, "unsupported ledger operation" unless DELTAS.key?(@entry_type)
        raise ArgumentError, "amount must be positive" unless @amount.positive?

        ActiveRecord::Base.transaction do
          allocation = Oja::PlanAllocation.lock.find(@allocation.id)
          existing = Oja::FinancialLedgerEntry.find_by(allocation_id: allocation.id, idempotency_key: @idempotency_key.to_s)
          return Result.new(applied: true, reason: "operation_replayed", entry: existing) if existing

          if @entry_type == "consume" || @entry_type == "release"
            raise ArgumentError, "reserved balance is insufficient" unless allocation.reserved_minor >= @amount
          elsif @entry_type == "reverse"
            raise ArgumentError, "consumed balance is insufficient" unless allocation.consumed_minor >= @amount
          end

          operation_id = Oja::Idempotency.operation_id(prefix: @entry_type, idempotency_key: @idempotency_key)
          entry = Oja::FinancialLedgerEntry.create!(
            allocation_id: allocation.id, operation_id:, idempotency_key: @idempotency_key.to_s,
            entry_type: @entry_type, amount_minor: @amount, currency: allocation.currency,
            correlation_id: @correlation_id.to_s, metadata: @metadata
          )
          DELTAS.fetch(@entry_type).each { |field, delta| allocation[field] += delta * @amount }
          allocation.available_minor
          allocation.save!
          Result.new(applied: true, reason: "operation_applied", entry:)
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      end
    end
  end
end
