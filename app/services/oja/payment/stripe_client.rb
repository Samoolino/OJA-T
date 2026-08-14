module Oja
  module Payment
    class StripeClient
      def initialize(secret_key: ENV.fetch("STRIPE_SECRET_KEY"))
        @secret_key = secret_key
      end

      def create_payment_intent(amount:, currency:, metadata:, idempotency_key:)
        stripe_payment_intent = ::Stripe::PaymentIntent.create(
          {
            amount: amount,
            currency: currency,
            metadata: metadata
          },
          { idempotency_key: idempotency_key }
        )

        {
          id: stripe_payment_intent.id,
          status: stripe_payment_intent.status,
          metadata: stripe_payment_intent.metadata
        }
      end

      def verify_webhook(payload:, signature:)
        ::Stripe::Webhook.construct_event(
          payload,
          signature,
          ENV.fetch("STRIPE_WEBHOOK_SECRET")
        )
      end
    end
  end
end
