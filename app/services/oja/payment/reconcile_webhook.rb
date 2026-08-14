module Oja
  module Payment
    class ReconcileWebhook
      PAYMENT_STATES = {
        "payment_intent.succeeded" => :succeeded,
        "payment_intent.payment_failed" => :failed,
        "payment_intent.canceled" => :canceled
      }.freeze

      def self.call(provider:, event:, payment_intent: nil)
        new(provider: provider, event: event, payment_intent: payment_intent).call
      end

      def initialize(provider:, event:, payment_intent: nil)
        @provider = provider
        @event = event
        @payment_intent = payment_intent
      end

      def call
        event_id = event.fetch(:id)
        type = event.fetch(:type)
        external_reference = event.fetch(:external_reference)

        webhook = WebhookEvent.find_or_create_by!(event_id: event_id) do |record|
          record.provider = provider
          record.event_type = type
          record.external_reference = external_reference
        end

        return payment_intent if webhook.persisted? && !webhook.previously_new_record?

        intent = payment_intent || PaymentIntent.find_by!(id: external_reference)
        next_status = PAYMENT_STATES[type]
        return intent unless next_status

        intent.with_lock do
          intent.update!(status: next_status)
        end

        intent
      end

      private

      attr_reader :provider, :event, :payment_intent
    end
  end
end
