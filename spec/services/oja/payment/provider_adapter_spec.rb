require "rails_helper"

RSpec.describe Oja::Payment::ProviderAdapter do
  subject(:adapter) { described_class.new }

  it "requires payment execution to be implemented by a provider" do
    expect {
      adapter.authorize_or_charge(
        payment_intent: instance_double(Oja::PaymentIntent),
        amount: 100,
        currency: "NGN",
        idempotency_key: "pi-test"
      )
    }.to raise_error(NotImplementedError)
  end

  it "requires webhook verification to be implemented by a provider" do
    expect {
      adapter.verify_webhook(payload: "{}", signature: "signature")
    }.to raise_error(NotImplementedError)
  end

  it "builds a provider-neutral result" do
    result = described_class.build_result(
      accepted: true,
      provider_reference: "provider-123",
      status: "accepted",
      raw_metadata: { "provider" => "test" }
    )

    expect(result.accepted).to be(true)
    expect(result.provider_reference).to eq("provider-123")
    expect(result.status).to eq("accepted")
  end
end
