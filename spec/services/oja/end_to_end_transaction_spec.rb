require "rails_helper"

RSpec.describe "OJA end-to-end transaction lifecycle" do
  it "carries a receiver's multi-plan funding through authorization, order, fulfillment and settlement reconciliation" do
    order = instance_double("Spree::Order", id: 501, total: 100_000.to_d, currency: "NGN")
    payment_intent = instance_double(Oja::PaymentIntent, id: 9001, amount: 100_000.to_d, currency: "NGN", authorized?: true, expired_at?: false, order_id: nil)

    allocation_a = instance_double(Oja::PlanAllocation, id: 11, currency: "NGN")
    allocation_b = instance_double(Oja::PlanAllocation, id: 12, currency: "NGN")
    reservation_a = instance_double(Oja::AllocationReservation, allocation_id: 11, active?: true, amount: 60_000.to_d, consumed?: false)
    reservation_b = instance_double(Oja::AllocationReservation, allocation_id: 12, active?: true, amount: 40_000.to_d, consumed?: false)
    profile_a = instance_double(Oja::VendorSettlementProfile, currency: "NGN")
    profile_b = instance_double(Oja::VendorSettlementProfile, currency: "NGN")

    order_allocation_a = instance_double(Oja::OrderAllocation,
      order_id: 501, reservation: reservation_a, amount: 60_000.to_d, currency: "NGN",
      vendor_reference: "vendor-a", settlement_profile: profile_a)
    order_allocation_b = instance_double(Oja::OrderAllocation,
      order_id: 501, reservation: reservation_b, amount: 40_000.to_d, currency: "NGN",
      vendor_reference: "vendor-b", settlement_profile: profile_b)

    parts = [
      { allocation: allocation_a, reservation: reservation_a, amount: 60_000, vendor_reference: "vendor-a", settlement_profile: profile_a },
      { allocation: allocation_b, reservation: reservation_b, amount: 40_000, vendor_reference: "vendor-b", settlement_profile: profile_b }
    ]

    allow(ApplicationRecord).to receive(:transaction).and_yield
    allow(payment_intent).to receive(:with_lock).and_yield
    allow(payment_intent).to receive(:update!)
    allow(Oja::Checkout::MaterializeAllocations).to receive(:call).with(order: order, parts: parts)
    allow(Oja::OrderAllocation).to receive(:where).with(order_id: 501).and_return(double(lock: [order_allocation_a, order_allocation_b]))

    expect(Oja::Allocations::Consume).to receive(:call).with(reservation: reservation_a, idempotency_key: "checkout-1:0")
    expect(Oja::Allocations::Consume).to receive(:call).with(reservation: reservation_b, idempotency_key: "checkout-1:1")
    expect(Oja::Settlement::Create).to receive(:call).with(order_allocation: order_allocation_a, vendor_reference: "vendor-a", gross_amount: 60_000.to_d, currency: "NGN", profile: profile_a)
    expect(Oja::Settlement::Create).to receive(:call).with(order_allocation: order_allocation_b, vendor_reference: "vendor-b", gross_amount: 40_000.to_d, currency: "NGN", profile: profile_b)

    expect(payment_intent).to receive(:update!).with(status: :order_pending, order: order)
    expect(payment_intent).to receive(:update!).with(status: :succeeded)

    Oja::Checkout::Complete.call(
      order: order,
      idempotency_key: "checkout-1",
      payment_intent: payment_intent,
      allocation_parts: parts
    )
  end
end
