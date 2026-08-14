require "rails_helper"

RSpec.describe Oja::Settlement::Route do
  let(:settlement) { instance_double(Oja::VendorSettlement, id: 42) }
  let(:scheduler) { class_double(Oja::Settlement::Scheduler, schedule: :scheduled) }

  it "schedules an instant vendor settlement using the vendor delay window" do
    profile = instance_double(Oja::VendorSettlementProfile,
      settlement_strategy: "instant",
      settlement_delay_window: 7200)

    expect(scheduler).to receive(:schedule).with(42, 7200)
    expect(described_class.call(settlement: settlement, profile: profile, scheduler: scheduler)).to eq(:scheduled)
  end

  it "leaves threshold-batched settlements awaiting the batch condition" do
    profile = instance_double(Oja::VendorSettlementProfile, settlement_strategy: "threshold_batched")

    expect(scheduler).not_to receive(:schedule)
    expect(described_class.call(settlement: settlement, profile: profile, scheduler: scheduler)).to eq(:awaiting_threshold)
  end

  it "rejects unsupported strategies" do
    profile = instance_double(Oja::VendorSettlementProfile, settlement_strategy: "unknown")

    expect {
      described_class.call(settlement: settlement, profile: profile, scheduler: scheduler)
    }.to raise_error(ArgumentError, /unsupported settlement strategy/)
  end
end
