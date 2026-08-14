module Oja
  module Payment
    module Providers
      class StripeAdapter < ProviderAdapter
        def initialize(client:)
          @client = client
        end

        def authorize_or_charge(payment_intent:, amount:, currency:, idempotency_key:)
          response = @client.create_payment_intent(
            amount: amount,
            currency: currency.downcase,
            metadata: {
              oja_payment_intent_id: payment_intent.id,
              oja_idempotency_key: idempotency_key
            },
            idempotency_key: idempotency_key
          )

          ProviderAdapter.build_result(
            accepted: true,
            provider_reference: response.fetch(:id),
            status: response.fetch(:status),
            raw_metadata: response
          )
        end

        def verify_webhook(payload:, signature:)
          @client.verify_webhook(payload: payload, signature: signature)
        end
      end
    end
  end
end
