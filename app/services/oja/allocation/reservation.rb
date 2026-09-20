module Oja
  module Allocation
    class Reservation
      Result = Struct.new(:reserved, :reason, :amount_minor, :currency, :evidence, keyword_init: true)
      def self.call(**kwargs) = new(**kwargs).call
      def initialize(allocation:, amount_minor:, beneficiary_id:, idempotency_key:, correlation_id:, context: {})
        @allocation, @amount_minor, @beneficiary_id = allocation, Integer(amount_minor), beneficiary_id.to_s
        @idempotency_key, @correlation_id, @context = idempotency_key, correlation_id, context
      end
      def call
        Oja::Idempotency.validate!(@idempotency_key)
        raise ArgumentError, "correlation_id is required" if @correlation_id.to_s.empty?
        ActiveRecord::Base.transaction do
          allocation = Oja::PlanAllocation.lock.find(@allocation.id)
          existing = Oja::FinancialLedgerEntry.find_by(allocation_id: allocation.id, idempotency_key: @idempotency_key.to_s)
          if existing
            return Result.new(reserved: existing.entry_type == "reserve", reason: existing.entry_type == "reserve" ? "reservation_replayed" : "idempotency_conflict", amount_minor: existing.amount_minor, currency: existing.currency, evidence: existing.metadata)
          end
          auth = Oja::Allocation::Authorization.call(allocation:, amount_minor: @amount_minor, beneficiary_id: @beneficiary_id, context: @context)
          return Result.new(reserved: false, reason: auth.reason, amount_minor: @amount_minor, currency: auth.currency, evidence: auth.evidence) unless auth.allowed
          entry = Oja::FinancialLedgerEntry.create!(
            allocation_id: allocation.id,
            operation_id: Oja::Idempotency.operation_id(prefix: "reserve", idempotency_key: @idempotency_key),
            idempotency_key: @idempotency_key.to_s, entry_type: "reserve", amount_minor: @amount_minor,
            currency: allocation.currency, correlation_id: @correlation_id.to_s, metadata: auth.evidence
          )
          allocation.reserved_minor += @amount_minor
          allocation.save!
          Result.new(reserved: true, reason: "reservation_created", amount_minor: @amount_minor, currency: allocation.currency, evidence: auth.evidence.merge("operation_id" => entry.operation_id))
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      rescue ArgumentError, TypeError
        Result.new(reserved: false, reason: "invalid_reservation_request", amount_minor: @amount_minor, currency: nil, evidence: {})
      end
    end
  end
end
