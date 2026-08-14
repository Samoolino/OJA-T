require "rails_helper"

RSpec.describe Oja::Payment::Execute do
  let(:payment_intent) do
    instance_double(
      Oja::PaymentIntent,
      idempotency_key: "oja-pi-123",
      amount: 12_500,
      currency: "NGN"
    )
  end
  let(:adapter) { instance_double(Oja::Payment::ProviderAdapter) }

  it "passes the PaymentIntent funding request to the provider adapter" do
    result = Oja::Payment::ProviderAdapter.build_result(
      accepted: true,
      provider_reference: "provider-123",
      status: "accepted",
      raw_metadata: { provider: "test" }
    )

    expect(adapter).to receive(:authorize_or_charge).with(
      payment_intent: payment_intent,
      amount: 12_500,
      currency: "NGN",
      idempotency_key: "oja-pi-123"
    ).and_return(result)

    expect(payment_intent).to receive(:respond_to?).with(:provider_reference=).and_return(false)
    expect(payment_intent).to receive(:respond_to?).with(:provider_status=).and_return(false)
    expect(payment_intent).to receive(:respond_to?).with(:provider_metadata=).and_return(false)

    expect(
      described_class.call(payment_intent: payment_intent, adapter: adapter)
    ).to eq(result)
  end

  it "allows an explicit idempotency key for a provider retry" do
    result = Oja::Payment::ProviderAdapter.build_result(
      accepted: true,
      provider_reference: "provider-456",
      status: "accepted"
    )

    expect(adapter).to receive(:authorize_or_charge).with(
      payment_intent: payment_intent,
      amount: 12_500,
      currency: "NGN",
      idempotency_key: "retry-key"
    ).and_return(result)

    allow(payment_intent).to receive(:respond_to?).and_return(false)

    expect(
      described_class.call(
        payment_intent: payment_intent,
        adapter: adapter,
        idempotency_key: "retry-key"
      )
    ).to eq(result)
  end
end
