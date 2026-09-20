module Oja
  module Funding
    class Issue
      Result = Struct.new(:accepted, :reason, :evidence, keyword_init: true)

      def self.call(plan:, amount_minor:, currency:, source_type:, source_reference:, idempotency_key:, correlation_id:)
        new(plan:, amount_minor:, currency:, source_type:, source_reference:, idempotency_key:, correlation_id:).call
      end

      def initialize(plan:, amount_minor:, currency:, source_type:, source_reference:, idempotency_key:, correlation_id:)
        @plan = plan
        @amount_minor = amount_minor
        @currency = currency
        @source_type = source_type
        @source_reference = source_reference
        @idempotency_key = idempotency_key
        @correlation_id = correlation_id
      end

      def call
        Oja::Idempotency.validate!(@idempotency_key)
        raise ArgumentError, "correlation_id is required" if @correlation_id.to_s.empty?

        validation = ValidateIngress.call(
          amount_minor: @amount_minor,
          currency: @currency,
          source_type: @source_type,
          source_reference: @source_reference
        )
        return Result.new(accepted: false, reason: validation.reason, evidence: validation.evidence) unless validation.valid

        Result.new(
          accepted: true,
          reason: "funding_ingress_accepted",
          evidence: validation.evidence.merge(
            "plan_id" => @plan.respond_to?(:id) ? @plan.id : nil,
            "idempotency_key" => @idempotency_key.to_s,
            "correlation_id" => @correlation_id.to_s
          ).compact
        )
      rescue ArgumentError
        Result.new(accepted: false, reason: "invalid_funding_request", evidence: {})
      end
    end
  end
end
