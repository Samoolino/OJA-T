require "rails_helper"

RSpec.describe Oja::Payment::Providers::StripeAdapter do
  let(:client) { instance_double("StripeClient") }
  let(:adapter) { described_class.new(client: client) }
  let(:payment_intent) { instance_double(Oja::PaymentIntent, id: 42) }

  it "passes the OJA idempotency key through to Stripe" do
    response = {
      id: "pi_test_123",
      status: "requires_payment_method"
    }

    expect(client).to receive(:create_payment_intent).with(
      amount: 125_00,
      currency: "ngn",
      metadata: {
        oja_payment_intent_id: 42,
        oja_idempotency_key: "oja-pi-123"
      },
      idempotency_key: "oja-pi-123"
    ).and_return(response)

    result = adapter.authorize_or_charge(
      payment_intent: payment_intent,
      amount: 125_00,
      currency: "NGN",
      idempotency_key: "oja-pi-123"
    )

    expect(result.accepted).to be(true)
    expect(result.provider_reference).to eq("pi_test_123")
    expect(result.status).to eq("requires_payment_method")
  end

  it "delegates signed webhook verification to the provider client" do
    expect(client).to receive(:verify_webhook)
      .with(payload: "payload", signature: "signature")
      .and_return({ event_id: "evt_123" })

    expect(adapter.verify_webhook(payload: "payload", signature: "signature"))
      .to eq({ event_id: "evt_123" })
  end
end
