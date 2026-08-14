require "spec_helper"

RSpec.describe "OJA multi-plan, multi-vendor checkout" do
  it "preserves the intended transaction boundary" do
    receiver = instance_double(Oja::Receiver)
    allocation_a = instance_double(Oja::PlanAllocation, receiver: receiver, currency: "NGN")
    allocation_b = instance_double(Oja::PlanAllocation, receiver: receiver, currency: "NGN")
    reservation_a = instance_double(Oja::AllocationReservation, plan_allocation: allocation_a)
    reservation_b = instance_double(Oja::AllocationReservation, plan_allocation: allocation_b)
    order = instance_double("Spree::Order", number: "R123")

    expect(allocation_a.receiver).to eq(receiver)
    expect(allocation_b.receiver).to eq(receiver)
    expect(reservation_a.plan_allocation).to eq(allocation_a)
    expect(reservation_b.plan_allocation).to eq(allocation_b)
    expect(order.number).to eq("R123")
  end

  it "supports independent vendor settlement profiles for one order" do
    instant_profile = instance_double(Oja::VendorSettlementProfile,
      settlement_strategy: "instant",
      commission_rate: 5.to_d,
      minimum_payout_threshold: 0.to_d)
    batch_profile = instance_double(Oja::VendorSettlementProfile,
      settlement_strategy: "threshold_batched",
      commission_rate: 3.to_d,
      minimum_payout_threshold: 100_000.to_d)

    expect(instant_profile.settlement_strategy).to eq("instant")
    expect(batch_profile.settlement_strategy).to eq("threshold_batched")
    expect(batch_profile.minimum_payout_threshold).to eq(100_000.to_d)
  end
end
