module Spree
  module OrderDecorator
    def self.prepended(base)
      base.state_machine.after_transition(to: :complete) do |order|
        payment_intent = Oja::PaymentIntent.find_by(order_id: order.id)
        next unless payment_intent

        Oja::Checkout::SpreeOrderCompletion.call(
          order: order,
          payment_intent: payment_intent,
          idempotency_key: payment_intent.idempotency_key || "spree-order:#{order.number}"
        )
      end
    end
  end
end

Spree::Order.prepend(Spree::OrderDecorator)
