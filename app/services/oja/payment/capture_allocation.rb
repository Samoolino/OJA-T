module Oja
  module Payment
    class CaptureAllocation
      Result = Struct.new(:captured, :reason, :amount_minor, :currency, :evidence, keyword_init: true)

      def self.call(allocation:, beneficiary_id:, amount_minor:, currency:, provider:, provider_event_id:, payment_reference:, order_reference:, correlation_id:, idempotency_key:, payload:, context: {})
        new(allocation:, beneficiary_id:, amount_minor:, currency:, provider:, provider_event_id:, payment_reference:, order_reference:, correlation_id:, idempotency_key:, payload:, context:).call
      end

      def initialize(**attrs)
        @attrs = attrs
      end

      def call
        Oja::Idempotency.validate!(@attrs[:idempotency_key])
        raise ArgumentError, "correlation_id is required" if @attrs[:correlation_id].to_s.empty?

        ActiveRecord::Base.transaction do
          allocation = Oja::PlanAllocation.lock.find(@attrs[:allocation].id)
          existing = allocation.ledger_entries.find_by(idempotency_key: @attrs[:idempotency_key].to_s)
          return Result.new(captured: true, reason: "capture_replayed", amount_minor: existing.amount_minor, currency: existing.currency, evidence: existing.metadata) if existing&.entry_type == "consume"

          authorization = Oja::Allocation::Authorization.call(
            allocation:,
            amount_minor: Integer(@attrs[:amount_minor]),
            beneficiary_id: @attrs[:beneficiary_id],
            context: @attrs[:context]
          )
          return Result.new(captured: false, reason: authorization.reason, amount_minor: @attrs[:amount_minor], currency: authorization.currency, evidence: authorization.evidence) unless authorization.allowed

          evidence = Oja::Payment::EvidenceIngestion.call(
            provider: @attrs[:provider],
            provider_event_id: @attrs[:provider_event_id],
            event_type: "payment_captured",
            payment_reference: @attrs[:payment_reference],
            order_reference: @attrs[:order_reference],
            currency: @attrs[:currency],
            amount_minor: @attrs[:amount_minor],
            correlation_id: @attrs[:correlation_id],
            payload: @attrs[:payload]
          )

          reconciliation = Oja::Reconciliation::Compare.call(
            provider: @attrs[:provider],
            provider_event_id: @attrs[:provider_event_id],
            payment_reference: @attrs[:payment_reference],
            order_reference: @attrs[:order_reference],
            expected_currency: allocation.currency,
            expected_amount_minor: @attrs[:amount_minor],
            observed_currency: evidence.event.currency,
            observed_amount_minor: evidence.event.amount_minor,
            correlation_id: @attrs[:correlation_id]
          )
          return Result.new(captured: false, reason: "reconciliation_exception", amount_minor: @attrs[:amount_minor], currency: allocation.currency, evidence: { "reconciliation_status" => reconciliation.status }) unless reconciliation.status == "MATCHED"

          return Result.new(captured: false, reason: "insufficient_reserved_balance", amount_minor: @attrs[:amount_minor], currency: allocation.currency, evidence: {}) unless allocation.reserved_minor >= Integer(@attrs[:amount_minor])

          entry = Oja::FinancialLedgerEntry.create!(
            allocation_id: allocation.id,
            operation_id: Oja::Idempotency.operation_id(prefix: "consume", idempotency_key: @attrs[:idempotency_key]),
            idempotency_key: @attrs[:idempotency_key].to_s,
            entry_type: "consume",
            amount_minor: Integer(@attrs[:amount_minor]),
            currency: allocation.currency,
            correlation_id: @attrs[:correlation_id].to_s,
            source_type: "payment_evidence",
            source_id: evidence.event.id.to_s,
            metadata: { "provider" => @attrs[:provider].to_s, "provider_event_id" => @attrs[:provider_event_id].to_s, "payment_reference" => @attrs[:payment_reference].to_s }
          )
          allocation.reserved_minor -= Integer(@attrs[:amount_minor])
          allocation.consumed_minor += Integer(@attrs[:amount_minor])
          allocation.save!

          Result.new(captured: true, reason: "capture_accepted", amount_minor: entry.amount_minor, currency: allocation.currency, evidence: { "ledger_operation_id" => entry.operation_id, "reconciliation_status" => reconciliation.status })
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      rescue ArgumentError, TypeError
        Result.new(captured: false, reason: "invalid_capture_request", amount_minor: 0, currency: nil, evidence: {})
      end
    end
  end
end
