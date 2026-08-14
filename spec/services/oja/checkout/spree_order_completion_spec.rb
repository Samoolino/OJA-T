require "rails_helper"

RSpec.describe Oja::Checkout::SpreeOrderCompletion do
  describe ".call" do
    it "requires an authorized PaymentIntent" do
      payment_intent = instance_double(Oja::PaymentIntent, authorized?: false)
      order = instance_double(Spree::Order, id: 42)

      expect {
        described_class.call(order: order, payment_intent: payment_intent, idempotency_key: "pi-1")
      }.to raise_error(ArgumentError, "payment intent is not authorized")
    end

    it "does not relink a PaymentIntent already attached to another order" do
      payment_intent = instance_double(Oja::PaymentIntent, authorized?: true, order_id: 7, succeeded?: false)
      order = instance_double(Spree::Order, id: 42)

      expect {
        described_class.call(order: order, payment_intent: payment_intent, idempotency_key: "pi-2")
      }.to raise_error(ArgumentError, "payment intent already linked to another order")
    end
  end
end
