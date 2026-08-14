require "rails_helper"

RSpec.describe Oja::Payment::StripeClient do
  subject(:client) { described_class.new(secret_key: "sk_test") }

  it "requires the Stripe SDK to create a payment intent with an idempotency key" do
    payment_intent = instance_double(
      Stripe::PaymentIntent,
      id: "pi_123",
      status: "requires_payment_method",
      metadata: { "oja_payment_intent_id" => "42" }
    )

    expect(Stripe::PaymentIntent).to receive(:create).with(
      {
        amount: 12_500,
        currency: "ngn",
        metadata: { oja_payment_intent_id: 42 }
      },
      { idempotency_key: "oja-123" }
    ).and_return(payment_intent)

    result = client.create_payment_intent(
      amount: 12_500,
      currency: "ngn",
      metadata: { oja_payment_intent_id: 42 },
      idempotency_key: "oja-123"
    )

    expect(result[:id]).to eq("pi_123")
    expect(result[:status]).to eq("requires_payment_method")
  end

  it "delegates webhook signature verification to Stripe" do
    event = instance_double(Stripe::Event)

    expect(Stripe::Webhook).to receive(:construct_event)
      .with("payload", "signature", "whsec_test")
      .and_return(event)

    allow(ENV).to receive(:fetch).with("STRIPE_WEBHOOK_SECRET").and_return("whsec_test")

    expect(client.verify_webhook(payload: "payload", signature: "signature")).to eq(event)
  end
end
