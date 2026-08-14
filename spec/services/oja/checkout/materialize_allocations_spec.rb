require "spec_helper"

RSpec.describe Oja::Checkout::MaterializeAllocations do
  it "creates order-allocation lineage for a reservation and vendor" do
    order = instance_double("Spree::Order", id: 42, currency: "NGN")
    allocation = instance_double(Oja::PlanAllocation, id: 7, currency: "NGN")
    reservation = instance_double(
      Oja::AllocationReservation,
      allocation_id: 7,
      active?: true,
      amount: 40_000.to_d
    )
    profile = instance_double(Oja::VendorSettlementProfile, currency: "NGN")
    record = instance_double(Oja::OrderAllocation)

    allow(ApplicationRecord).to receive(:transaction).and_yield
    expect(Oja::OrderAllocation).to receive(:create_or_find_by!).with(
      order_id: 42,
      allocation_id: 7
    ).and_yield(record)

    expect(record).to receive(:reservation=).with(reservation)
    expect(record).to receive(:amount=).with(40_000.to_d)
    expect(record).to receive(:currency=).with("NGN")
    expect(record).to receive(:vendor_reference=).with("vendor-1")
    expect(record).to receive(:settlement_profile=).with(profile)

    described_class.call(
      order: order,
      parts: [{
        allocation: allocation,
        reservation: reservation,
        amount: 40_000,
        vendor_reference: "vendor-1",
        settlement_profile: profile
      }]
    )
  end
end
