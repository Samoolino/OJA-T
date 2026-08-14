require "rails_helper"

RSpec.describe Oja::Settlement do
  subject(:settlement) do
    described_class.new(
      vendor_reference: "vendor_123",
      gross_amount: 10_000,
      platform_fee: 1_000,
      net_amount: 9_000,
      currency: "NGN",
      status: "pending",
      settlement_strategy: "delayed",
      settlement_reference: "set_123"
    )
  end

  it "accepts a valid settlement state" do
    expect(settlement).to be_valid
  end

  it "requires net amount to equal gross less platform fee" do
    settlement.net_amount = 8_000

    expect(settlement).not_to be_valid
    expect(settlement.errors[:net_amount]).to include("must equal gross amount less platform fee")
  end

  it "restricts settlement status and strategy values" do
    settlement.status = "unknown"
    settlement.settlement_strategy = "unknown"

    expect(settlement).not_to be_valid
    expect(settlement.errors[:status]).to be_present
    expect(settlement.errors[:settlement_strategy]).to be_present
  end
end
