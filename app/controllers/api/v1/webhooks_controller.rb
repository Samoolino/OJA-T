module Api
  module V1
    class WebhooksController < ActionController::API
      def payment
        raw_payload = request.raw_post
        Oja::Webhooks::VerifySignature.call(
          payload: raw_payload,
          signature: request.headers["X-OJA-Signature"]
        )

        payload = JSON.parse(raw_payload)
        event = Oja::WebhookEvent.create_or_find_by!(event_id: payload.fetch("event_id")) do |record|
          record.provider = payload.fetch("provider")
          record.event_type = payload.fetch("event_type")
          record.external_reference = payload.fetch("external_reference")
          record.payload = payload
        end

        unless event.processed_at
          Oja::Settlement::Reconcile.call(
            external_reference: event.external_reference,
            event_type: event.event_type
          )
          event.update!(processed_at: Time.current)
        end

        head :ok
      rescue JSON::ParserError, KeyError, ArgumentError, ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end
  end
end
