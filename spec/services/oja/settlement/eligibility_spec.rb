require "rails_helper"

RSpec.describe Oja::Settlement::Eligibility do
  let(:settlement) do
    instance_double(
      Oja::Settlement,
      status: "pending"
    )
  end

  before do
    allow(settlement).to receive(:reload).and_return(settlement)
    allow(settlement).to receive(:with_lock).and_yield
  end

  it "marks a settlement eligible only after payment, fulfillment, and delivery are confirmed" do
    expect(settlement).to receive(:update!).with(status: "eligible", eligible_at: kind_of(Time))

    described_class.call(
      settlement: settlement,
      payment_confirmed: true,
      fulfillment_complete: true,
      delivery_confirmed: true
    )
  end

  it "does not make a settlement eligible before delivery confirmation" do
    expect(settlement).not_to receive(:update!)

    described_class.call(
      settlement: settlement,
      payment_confirmed: true,
      fulfillment_complete: true,
      delivery_confirmed: false
    )
  end

  it "does not change an already eligible settlement" do
    allow(settlement).to receive(:status).and_return("eligible")
    expect(settlement).not_to receive(:update!)

    described_class.call(
      settlement: settlement,
      payment_confirmed: true,
      fulfillment_complete: true,
      delivery_confirmed: true
    )
  end

  it "does not change a settled settlement" do
    allow(settlement).to receive(:status).and_return("settled")
    expect(settlement).not_to receive(:update!)

    described_class.call(
      settlement: settlement,
      payment_confirmed: true,
      fulfillment_complete: true,
      delivery_confirmed: true
    )
  end
end
