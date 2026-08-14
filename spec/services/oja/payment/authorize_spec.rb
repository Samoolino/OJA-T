require "spec_helper"

RSpec.describe Oja::Payment::Authorize do
  let(:payment_intent) do
    instance_double(
      Oja::PaymentIntent,
      id: 17,
      amount: 100_000.to_d,
      currency: "NGN",
      nonce: "nonce-1",
      expires_at: 1.hour.from_now,
      idempotency_key: "pi-1",
      authorization_method: "biometric_p256"
    )
  end
  let(:verifier) { instance_double("P256Verifier", verify: true) }

  it "binds the signature verification to the payment intent transaction" do
    expect(payment_intent).to receive(:expired_at?).and_return(false)
    expect(verifier).to receive(:verify).with(
      signature: "sig",
      credential_reference: "cred-1",
      payload: include("OJA-PAYMENT:17:100000.0:NGN:nonce-1")
    ).and_return(true)
    expect(payment_intent).to receive(:with_lock).and_yield
    expect(payment_intent).to receive(:authorized?).and_return(false)
    expect(payment_intent).to receive(:pending?).and_return(true)
    expect(payment_intent).to receive(:requires_authorization?).and_return(false)
    expect(payment_intent).to receive(:update!).with(status: :authorized, authorized_at: kind_of(Time))

    described_class.call(
      payment_intent: payment_intent,
      signature: "sig",
      credential_reference: "cred-1",
      verifier: verifier
    )
  end

  it "rejects an invalid signature" do
    allow(payment_intent).to receive(:expired_at?).and_return(false)
    allow(verifier).to receive(:verify).and_return(false)

    expect do
      described_class.call(
        payment_intent: payment_intent,
        signature: "bad",
        credential_reference: "cred-1",
        verifier: verifier
      )
    end.to raise_error(ArgumentError, "authorization signature invalid")
  end
end
