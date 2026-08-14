require "rails_helper"

RSpec.describe Oja::Payment::ReconcileWebhook do
  let(:payment_intent) { create(:oja_payment_intent, status: :authorized) }

  let(:event) do
    {
      id: "evt_123",
      type: "payment_intent.succeeded",
      external_reference: payment_intent.id.to_s
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
