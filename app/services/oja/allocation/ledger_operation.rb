module Oja
  module Allocation
    class LedgerOperation
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
        raise ArgumentError, "invalid ledger operation" unless DELTAS.key?(@entry_type)
        raise ArgumentError, "amount must be positive" unless @amount.positive?

        ActiveRecord::Base.transaction do
          allocation = Oja::PlanAllocation.lock.find(@allocation.id)
          existing = Oja::FinancialLedgerEntry.find_by(allocation_id: allocation.id, idempotency_key: @idempotency_key.to_s)
          next existing if existing

          delta = DELTAS.fetch(@entry_type)
          delta.each { |field, sign| raise ArgumentError, "insufficient #{field}" if sign.negative? && allocation.public_send(field) < @amount }

          delta.each { |field, sign| allocation.public_send("#{field}=", allocation.public_send(field) + sign * @amount) }
          allocation.save!

          Oja::FinancialLedgerEntry.create!(
            allocation_id: allocation.id,
            operation_id: Oja::Idempotency.operation_id(prefix: @entry_type, idempotency_key: @idempotency_key),
            idempotency_key: @idempotency_key.to_s,
            entry_type: @entry_type,
            amount_minor: @amount,
            currency: allocation.currency,
            correlation_id: @correlation_id.to_s,
            metadata: @metadata
          )
        end
      end
    end
  end
end
