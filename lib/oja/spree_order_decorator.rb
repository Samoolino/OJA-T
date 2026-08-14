module Oja
  module SpreeOrderDecorator
    def self.prepended(base)
      base.state_machine.after_transition(to: :complete) do
        Oja::Checkout::SpreeOrderCompletion.call(
          order: self,
          idempotency_key: "spree-order-complete:#{number}"
        )
      end
    end
  end
end

if defined?(Spree::Order)
  Spree::Order.prepend(Oja::SpreeOrderDecorator)
end
