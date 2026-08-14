module Api
  module V1
    class WebhooksController < ActionController::API
      def stripe
        raw_payload = request.raw_post
        signature = request.headers["Stripe-Signature"]
        event = Oja::Payment::StripeClient.new.verify_webhook(
          payload: raw_payload,
          signature: signature
        )

        stripe_payment_intent_id = event.data.object.id

        Oja::Payment::ReconcileWebhook.call(
          provider: "stripe",
          event: {
            id: event.id,
            type: event.type,
            external_reference: stripe_payment_intent_id
          }
        )

        head :ok
      rescue ::Stripe::SignatureVerificationError, JSON::ParserError, KeyError, ArgumentError, ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end
  end
end
