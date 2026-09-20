module Oja
  module Funding
    class Issue
      Result = Struct.new(:funded, :reason, :amount_minor, :currency, :evidence, keyword_init: true)
      def self.call(**kwargs) = new(**kwargs).call
      def initialize(allocation:, amount_minor:, currency:, source_type:, source_reference:, provider:, status:, idempotency_key:, correlation_id:, metadata: {})
        @allocation, @amount_minor, @currency = allocation, Integer(amount_minor), currency.to_s.upcase
        @source_type, @source_reference, @provider, @status = source_type, source_reference, provider, status
        @idempotency_key, @correlation_id, @metadata = idempotency_key, correlation_id, metadata
      end
      def call
        Oja::Idempotency.validate!(@idempotency_key)
        raise ArgumentError, "correlation_id is required" if @correlation_id.to_s.empty?
        ActiveRecord::Base.transaction do
          allocation = Oja::PlanAllocation.lock.find(@allocation.id)
          existing = Oja::FinancialLedgerEntry.find_by(allocation_id: allocation.id, idempotency_key: @idempotency_key.to_s)
          return Result.new(funded: true, reason: "funding_replayed", amount_minor: existing.amount_minor, currency: existing.currency, evidence: existing.metadata) if existing
          evidence = Oja::Funding::ValidateIngress.call(amount_minor: @amount_minor, currency: @currency, source_type: @source_type, source_reference: @source_reference, provider: @provider, status: @status)
          entry = Oja::FinancialLedgerEntry.create!(allocation_id: allocation.id, operation_id: Oja::Idempotency.operation_id(prefix: "fund", idempotency_key: @idempotency_key), idempotency_key: @idempotency_key.to_s, entry_type: "fund", amount_minor: @amount_minor, currency: @currency, correlation_id: @correlation_id.to_s, source_type: @source_type, source_id: @source_reference, metadata: @metadata.merge("funding_evidence" => evidence))
          allocation.funded_minor += @amount_minor
          allocation.save!
          Result.new(funded: true, reason: "funding_accepted", amount_minor: @amount_minor, currency: @currency, evidence: evidence.merge("operation_id" => entry.operation_id))
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      rescue ArgumentError, TypeError
        Result.new(funded: false, reason: "invalid_funding_request", amount_minor: @amount_minor, currency: @currency, evidence: {})
      end
    end
  end
end
