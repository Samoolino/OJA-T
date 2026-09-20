module Oja
  module Allocation
    class Reservation
      Result = Struct.new(:reserved, :reason, :amount_minor, :currency, :evidence, keyword_init: true)

      def self.call(allocation:, amount_minor:, beneficiary_id:, idempotency_key:, correlation_id:, context: {})
        new(allocation:, amount_minor:, beneficiary_id:, idempotency_key:, correlation_id:, context:).call
      end

      def initialize(allocation:, amount_minor:, beneficiary_id:, idempotency_key:, correlation_id:, context:)
        @allocation = allocation
        @amount_minor = Integer(amount_minor)
        @beneficiary_id = beneficiary_id.to_s
        @idempotency_key = idempotency_key
        @correlation_id = correlation_id
        @context = context
      end

      def call
        Oja::Idempotency.validate!(@idempotency_key)
        raise ArgumentError, "correlation_id is required" if @correlation_id.to_s.empty?
        authorization = Oja::Allocation::Authorization.call(
          allocation: @allocation,
          amount_minor: @amount_minor,
          beneficiary_id: @beneficiary_id,
          context: @context
        )
        return Result.new(reserved: false, reason: authorization.reason, amount_minor: @amount_minor, currency: authorization.currency, evidence: authorization.evidence) unless authorization.allowed

        Result.new(
          reserved: true,
          reason: "reservation_authorized",
          amount_minor: @amount_minor,
          currency: authorization.currency,
          evidence: authorization.evidence.merge(
            "idempotency_key" => @idempotency_key.to_s,
            "correlation_id" => @correlation_id.to_s
          )
        )
      rescue ArgumentError, TypeError
        Result.new(reserved: false, reason: "invalid_reservation_request", amount_minor: @amount_minor, currency: nil, evidence: {})
      end
    end
  end
end
