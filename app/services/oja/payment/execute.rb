module Oja
  module Payment
    class Execute
      def self.call(payment_intent:, adapter:, idempotency_key: nil)
        new(payment_intent: payment_intent, adapter: adapter, idempotency_key: idempotency_key).call
      end

      def initialize(payment_intent:, adapter:, idempotency_key: nil)
        @payment_intent = payment_intent
        @adapter = adapter
        @idempotency_key = idempotency_key || payment_intent.idempotency_key
      end

      def call
        result = @adapter.authorize_or_charge(
          payment_intent: @payment_intent,
          amount: @payment_intent.amount,
          currency: @payment_intent.currency,
          idempotency_key: @idempotency_key
        )

        persist_provider_result(result)
        result
      end

      private

      def persist_provider_result(result)
        attributes = {}
        attributes[:provider_reference] = result.provider_reference if @payment_intent.respond_to?(:provider_reference=)
        attributes[:provider_status] = result.status if @payment_intent.respond_to?(:provider_status=)
        attributes[:provider_metadata] = result.raw_metadata if @payment_intent.respond_to?(:provider_metadata=)
        @payment_intent.update!(attributes) if attributes.any?
      end
    end
  end
end
