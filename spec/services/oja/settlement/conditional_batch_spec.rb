require "spec_helper"

RSpec.describe Oja::Settlement::ConditionalBatch do
  let(:profile) do
    instance_double(Oja::VendorSettlementProfile,
      minimum_payout_threshold: 100_000.to_d,
      currency: "NGN",
      payout_destination_reference: "vendor-bank-1")
  end
  let(:gateway) { class_double(Oja::Settlement::TransferGateway) }

  it "does not transfer when the vendor has not reached the threshold" do
    low = instance_double(Oja::VendorSettlement, net_amount: 25_000.to_d)
    scope = class_double(Oja::VendorSettlement)
    allow(scope).to receive(:where).and_return([low])

    expect(gateway).not_to receive(:initiate)
    expect(described_class.call(vendor_reference: "vendor-1", profile: profile, scope: scope, transfer_gateway: gateway)).to eq(:below_threshold)
  end

  it "batches payable settlements after the threshold is reached" do
    first = instance_double(Oja::VendorSettlement, net_amount: 60_000.to_d)
    second = instance_double(Oja::VendorSettlement, net_amount: 50_000.to_d)
    scope = class_double(Oja::VendorSettlement)
    allow(scope).to receive(:where).and_return([first, second])
    allow(gateway).to receive(:initiate).and_return(Data.define(:success?, :reference).new(true, "TRX-1"))

    expect(first).to receive(:update!).with(status: :authorized, payout_reference: "TRX-1")
    expect(second).to receive(:update!).with(status: :authorized, payout_reference: "TRX-1")

    expect(described_class.call(vendor_reference: "vendor-1", profile: profile, scope: scope, transfer_gateway: gateway)).to eq(:authorized)
  end

  it "marks the batch failed when the transfer gateway rejects it" do
    settlement = instance_double(Oja::VendorSettlement, net_amount: 120_000.to_d)
    scope = class_double(Oja::VendorSettlement)
    allow(scope).to receive(:where).and_return([settlement])
    allow(gateway).to receive(:initiate).and_return(Data.define(:success?, :reference).new(false, nil))

    expect(settlement).to receive(:update!).with(status: :failed)
    expect(described_class.call(vendor_reference: "vendor-1", profile: profile, scope: scope, transfer_gateway: gateway)).to eq(:failed)
  end
end
