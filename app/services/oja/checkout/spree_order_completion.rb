module Oja
  module Checkout
    class SpreeOrderCompletion
      def self.call(order:, payment_intent:, idempotency_key:)
        raise ArgumentError, "payment intent is required" unless payment_intent
        raise ArgumentError, "payment intent is not authorized" unless payment_intent.authorized?
        if payment_intent.order_id.present? && payment_intent.order_id != order.id
          raise ArgumentError, "payment intent already linked to another order"
        end

        ApplicationRecord.transaction do
          payment_intent.with_lock do
            return order if payment_intent.succeeded?

            payment_intent.update!(order_id: order.id, idempotency_key: idempotency_key)
            Oja::Checkout::Complete.call(order: order, idempotency_key: idempotency_key)
            Oja::Fulfillment::Create.call(order: order, idempotency_key: idempotency_key)
            payment_intent.update!(status: :succeeded, completed_at: Time.current)
          end
        end

        order
      end
    end
  end
end
