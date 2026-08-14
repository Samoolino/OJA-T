require "rails_helper"

RSpec.describe Oja::Settlement::Eligibility do
  let!(:settlement) do
    Oja::Settlement.create!(
      vendor_reference: "vendor_123",
      gross_amount: 10_000,
      platform_fee: 1_000,
      net_amount: 9_000,
      currency: "NGN",
      status: "pending",
      settlement_strategy: "delayed",
      settlement_reference: "set_eligibility_123"
    )
  end

  it "marks a settlement eligible only after payment, fulfillment, and delivery are confirmed" do
    described_class.call(
      settlement: settlement,
      payment_confirmed: false,
      fulfillment_complete: true,
      delivery_confirmed: true
    )

    expect(settlement.reload.status).to eq("pending")

    described_class.call(
      settlement: settlement,
      payment_confirmed: true,
      fulfillment_complete: true,
      delivery_confirmed: true
    )

    expect(settlement.reload.status).to eq("eligible")
    expect(settlement.eligible_at).to be_present
  end

  it "does not make a settlement eligible before delivery confirmation" do
    described_class.call(
      settlement: settlement,
      payment_confirmed: true,
      fulfillment_complete: true,
      delivery_confirmed: false
    )

    expect(settlement.reload.status).to eq("pending")
    expect(settlement.eligible_at).to be_nil
  end

  it "does not change a settled settlement" do
    settlement.update!(status: "settled")

    described_class.call(
      settlement: settlement,
      payment_confirmed: true,
      fulfillment_complete: true,
      delivery_confirmed: true
    )

    expect(settlement.reload.status).to eq("settled")
  end
end
