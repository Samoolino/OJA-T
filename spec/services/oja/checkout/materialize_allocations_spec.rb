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

  it "materializes multiple allocations for different vendors on one order" do
    order = instance_double("Spree::Order", id: 99, currency: "NGN")
    allocation_a = instance_double(Oja::PlanAllocation, id: 11, currency: "NGN")
    allocation_b = instance_double(Oja::PlanAllocation, id: 12, currency: "NGN")
    reservation_a = instance_double(Oja::AllocationReservation, allocation_id: 11, active?: true, amount: 60_000.to_d)
    reservation_b = instance_double(Oja::AllocationReservation, allocation_id: 12, active?: true, amount: 40_000.to_d)
    profile_a = instance_double(Oja::VendorSettlementProfile, currency: "NGN")
    profile_b = instance_double(Oja::VendorSettlementProfile, currency: "NGN")
    record_a = instance_double(Oja::OrderAllocation)
    record_b = instance_double(Oja::OrderAllocation)

    allow(ApplicationRecord).to receive(:transaction).and_yield
    expect(Oja::OrderAllocation).to receive(:create_or_find_by!).with(order_id: 99, allocation_id: 11).and_yield(record_a)
    expect(Oja::OrderAllocation).to receive(:create_or_find_by!).with(order_id: 99, allocation_id: 12).and_yield(record_b)

    expect(record_a).to receive(:reservation=).with(reservation_a)
    expect(record_a).to receive(:amount=).with(60_000.to_d)
    expect(record_a).to receive(:currency=).with("NGN")
    expect(record_a).to receive(:vendor_reference=).with("vendor-a")
    expect(record_a).to receive(:settlement_profile=).with(profile_a)

    expect(record_b).to receive(:reservation=).with(reservation_b)
    expect(record_b).to receive(:amount=).with(40_000.to_d)
    expect(record_b).to receive(:currency=).with("NGN")
    expect(record_b).to receive(:vendor_reference=).with("vendor-b")
    expect(record_b).to receive(:settlement_profile=).with(profile_b)

    described_class.call(
      order: order,
      parts: [
        { allocation: allocation_a, reservation: reservation_a, amount: 60_000, vendor_reference: "vendor-a", settlement_profile: profile_a },
        { allocation: allocation_b, reservation: reservation_b, amount: 40_000, vendor_reference: "vendor-b", settlement_profile: profile_b }
      ]
    )
  end
end
