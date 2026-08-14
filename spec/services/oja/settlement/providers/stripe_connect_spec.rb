require "rails_helper"

RSpec.describe Oja::Settlement::Providers::StripeConnect do
  subject(:provider) do
    described_class.new(
      secret_key: "sk_test_oja",
      account_client: account_client,
      transfer_client: transfer_client
    )
  end

  let(:account_client) { class_double(Stripe::Account) }
  let(:transfer_client) { class_double(Stripe::Transfer) }
  let(:settlement) do
    instance_double(
      Oja::Settlement,
      status: "eligible",
      net_amount: 9_000,
      currency: "NGN",
      settlement_reference: "set_123",
      provider_reference: nil
    )
  end

  describe "#create_payout" do
    it "creates an idempotent Stripe transfer and persists its provider reference" do
      account = instance_double(Stripe::Account, capabilities: { "transfers" => "active" })
      transfer = instance_double(Stripe::Transfer, id: "tr_123")

      allow(account_client).to receive(:retrieve).with("acct_vendor_123").and_return(account)
      allow(transfer_client).to receive(:create).with(
        {
          amount: 9_000,
          currency: "ngn",
          destination: "acct_vendor_123",
          metadata: { oja_settlement_reference: "set_123" }
        },
        { idempotency_key: "set_123" }
      ).and_return(transfer)
      allow(settlement).to receive(:update!).with(status: "processing", provider_reference: "tr_123")

      result = provider.create_payout(settlement: settlement, connected_account_id: "acct_vendor_123")

      expect(result).to eq(id: "tr_123", status: "processing", reused: false)
    end

    it "reuses an existing provider reference without creating another transfer" do
      settlement_with_reference = instance_double(
        Oja::Settlement,
        status: "processing",
        provider_reference: "tr_existing"
      )

      expect(transfer_client).not_to receive(:create)

      result = provider.create_payout(
        settlement: settlement_with_reference,
        connected_account_id: "acct_vendor_123"
      )

      expect(result).to eq(id: "tr_existing", status: "processing", reused: true)
    end

    it "rejects settlements that are not eligible" do
      pending_settlement = instance_double(
        Oja::Settlement,
        status: "pending",
        provider_reference: nil
      )

      expect {
        provider.create_payout(settlement: pending_settlement, connected_account_id: "acct_vendor_123")
      }.to raise_error(described_class::NotEligible)
    end

    it "rejects connected accounts without active transfer capability" do
      account = instance_double(Stripe::Account, capabilities: { "transfers" => "inactive" })
      allow(account_client).to receive(:retrieve).with("acct_vendor_123").and_return(account)

      expect {
        provider.create_payout(settlement: settlement, connected_account_id: "acct_vendor_123")
      }.to raise_error(described_class::TransfersDisabled)

      expect(transfer_client).not_to receive(:create)
    end
  end
end
