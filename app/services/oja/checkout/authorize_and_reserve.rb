module Oja
  module Checkout
    class AuthorizeAndReserve
      Result = Struct.new(:authorized, :reserved, :reason, :amount_minor, :currency, :basket, :evidence, keyword_init: true)

      def self.call(allocation:, beneficiary_id:, line_items:, currency:, idempotency_key:, correlation_id:, context: {})
        new(allocation:, beneficiary_id:, line_items:, currency:, idempotency_key:, correlation_id:, context:).call
      end

      def initialize(allocation:, beneficiary_id:, line_items:, currency:, idempotency_key:, correlation_id:, context:)
        @allocation = allocation
        @beneficiary_id = beneficiary_id
        @line_items = line_items
        @currency = currency
        @idempotency_key = idempotency_key
        @correlation_id = correlation_id
        @context = context || {}
      end

      def call
        Oja::Idempotency.validate!(@idempotency_key)
        raise ArgumentError, "correlation_id is required" if @correlation_id.to_s.empty?

        basket = Oja::Checkout::ExactBasket.call(line_items: @line_items, currency: @currency)
        return Result.new(authorized: false, reserved: false, reason: basket.reason, amount_minor: 0, currency: basket.currency, basket:, evidence: {}) unless basket.valid

        reservation = Oja::Allocation::Reservation.call(
          allocation: @allocation,
          amount_minor: basket.amount_minor,
          beneficiary_id: @beneficiary_id,
          idempotency_key: @idempotency_key,
          correlation_id: @correlation_id,
          context: @context
        )

        Result.new(
          authorized: reservation.reserved,
          reserved: reservation.reserved,
          reason: reservation.reason,
          amount_minor: basket.amount_minor,
          currency: basket.currency,
          basket:,
          evidence: reservation.evidence
        )
      end
    end
  end
end
