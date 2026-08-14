require "rails_helper"

RSpec.describe Api::V1::WebhooksController, type: :controller do
  describe "POST #stripe" do
    let(:payload) do
      {
        id: "evt_123",
        object: "event",
        type: "payment_intent.succeeded",
        data: {
          object: {
            id: "pi_test_123",
            object: "payment_intent"
          }
        }
      }.to_json
    end

    let(:stripe_event) do
      instance_double(
        Stripe::Event,
        id: "evt_123",
        type: "payment_intent.succeeded",
        data: instance_double(
          Stripe::Event::Data,
          object: instance_double(Stripe::PaymentIntent, id: "pi_test_123")
        )
      )
    end

    before do
      allow_any_instance_of(Oja::Payment::StripeClient)
        .to receive(:verify_webhook)
        .and_return(stripe_event)

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

    it "verifies and reconciles a Stripe payment webhook" do
      request.headers["Stripe-Signature"] = "t=123,v1=test"

      post :stripe, body: payload

      expect(response).to have_http_status(:ok)
      expect(Oja::PaymentIntent.find_by(payment_intent_id: "pi_test_123")).to be_succeeded
    end

    it "rejects an invalid Stripe signature" do
      allow_any_instance_of(Oja::Payment::StripeClient)
        .to receive(:verify_webhook)
        .and_raise(Stripe::SignatureVerificationError.new("invalid signature", "signature"))

      request.headers["Stripe-Signature"] = "invalid"

      post :stripe, body: payload

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
