require "rails_helper"

RSpec.describe Oja::Payment::ReconcileWebhook do
  let(:payment_intent) do
    Oja::PaymentIntent.create!(
      payment_intent_id: "pi_test_123",
      amount: 12_500,
      currency: "NGN",
      funding_source: "card",
      authorization_method: "manual",
      nonce: SecureRandom.uuid,
      expires_at: 1.hour.from_now,
      status: :authorized
    )
  end

  let(:event) do
    {
      id: "evt_123",
      type: "payment_intent.succeeded",
      external_reference: payment_intent.payment_intent_id
    }
  end

  it "moves the PaymentIntent to succeeded" do
    described_class.call(provider: "stripe", event: event, payment_intent: payment_intent)

    expect(payment_intent.reload).to be_succeeded
    expect(Oja::WebhookEvent.find_by(event_id: "evt_123")).to be_present
  end

  it "does not apply a webhook twice" do
    described_class.call(provider: "stripe", event: event, payment_intent: payment_intent)
    payment_intent.update!(status: :failed)

    described_class.call(provider: "stripe", event: event, payment_intent: payment_intent)

    expect(payment_intent.reload).to be_failed
  end
end
