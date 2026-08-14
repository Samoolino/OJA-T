require "rails_helper"

RSpec.describe "OJA end-to-end transaction lifecycle" do
  it "carries a receiver's multi-plan funding through authorization, order, fulfillment, delivery and settlement reconciliation" do
    order = instance_double("Spree::Order", id: 501, total: 100_000.to_d, currency: "NGN")
    payment_intent = instance_double(Oja::PaymentIntent, id: 9001, amount: 100_000.to_d, currency: "NGN", authorized?: true, expired_at?: false, order_id: nil)

    allocation_a = instance_double(Oja::PlanAllocation, id: 11, currency: "NGN")
    allocation_b = instance_double(Oja::PlanAllocation, id: 12, currency: "NGN")
    reservation_a = instance_double(Oja::AllocationReservation, allocation_id: 11, active?: true, amount: 60_000.to_d, consumed?: false)
    reservation_b = instance_double(Oja::AllocationReservation, allocation_id: 12, active?: true, amount: 40_000.to_d, consumed?: false)
    profile_a = instance_double(Oja::VendorSettlementProfile, currency: "NGN", fulfillment_mode: "courier")
    profile_b = instance_double(Oja::VendorSettlementProfile, currency: "NGN", fulfillment_mode: "courier")

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

    fulfillment_a = instance_double(Oja::OrderFulfillment, order_id: 501, vendor_reference: "vendor-a", delivered?: false)
    settlement_a = instance_double(Oja::VendorSettlement,
      order_allocation: order_allocation_a, payout_reference: "payout-a", paid?: false, failed?: false)

    allow(ApplicationRecord).to receive(:transaction).and_yield
    allow(payment_intent).to receive(:with_lock).and_yield
    expect(payment_intent).to receive(:update!).with(status: :order_pending, order: order)
    expect(payment_intent).to receive(:update!).with(status: :succeeded)

    allow(Oja::Checkout::MaterializeAllocations).to receive(:call).with(order: order, parts: parts)
    allow(Oja::OrderAllocation).to receive(:where).with(order_id: 501).and_return(double(lock: [order_allocation_a, order_allocation_b]))

    expect(Oja::Allocations::Consume).to receive(:call).with(reservation: reservation_a, idempotency_key: "checkout-1:0")
    expect(Oja::Allocations::Consume).to receive(:call).with(reservation: reservation_b, idempotency_key: "checkout-1:1")
    expect(Oja::Settlement::Create).to receive(:call).with(order_allocation: order_allocation_a, vendor_reference: "vendor-a", gross_amount: 60_000.to_d, currency: "NGN", profile: profile_a)
    expect(Oja::Settlement::Create).to receive(:call).with(order_allocation: order_allocation_b, vendor_reference: "vendor-b", gross_amount: 40_000.to_d, currency: "NGN", profile: profile_b)

    Oja::Checkout::Complete.call(
      order: order,
      idempotency_key: "checkout-1",
      payment_intent: payment_intent,
      allocation_parts: parts
    )

    allow(Oja::OrderAllocation).to receive(:where).with(order_id: 501, vendor_reference: "vendor-a").and_return(double(select: double))
    allow(Oja::VendorFulfillmentProfile).to receive(:find_by).with(vendor_reference: "vendor-a").and_return(profile_a)
    allow(Oja::OrderAllocation).to receive(:where).with(order_id: 501).and_return(double(each_with_index: nil))

    expect(Oja::OrderFulfillment).to receive(:create_or_find_by!).with(order_id: 501, vendor_reference: "vendor-a").and_yield(double(fulfillment_mode: nil, status: nil, idempotency_key: nil))
    allow(Oja::OrderFulfillment).to receive(:create_or_find_by!).with(order_id: 501, vendor_reference: "vendor-b").and_return(double)

    Oja::Fulfillment::Create.call(order: order, idempotency_key: "fulfill-1")

    allow(fulfillment_a).to receive(:with_lock).and_yield
    allow(fulfillment_a).to receive(:update!).with(hash_including(status: "delivered"))
    allow(Oja::OrderAllocation).to receive(:where).with(order_id: 501, vendor_reference: "vendor-a").and_return(double(select: [order_allocation_a.id]))
    allow(Oja::VendorSettlement).to receive(:where).and_return(double(find_each: [settlement_a]))
    allow(settlement_a).to receive(:update!).with(status: :payable)
    expect(Oja::Settlement::Route).to receive(:call).with(settlement: settlement_a, profile: profile_a)

    Oja::Fulfillment::ConfirmDelivery.call(fulfillment: fulfillment_a, confirmation_reference: "DEL-501-A")

    allow(Oja::VendorSettlement).to receive(:find_by!).with(payout_reference: "payout-a").and_return(settlement_a)
    allow(settlement_a).to receive(:with_lock).and_yield
    expect(settlement_a).to receive(:update!).with(status: :paid, settled_at: kind_of(Time))

    Oja::Settlement::Reconcile.call(
      external_reference: "payout-a",
      event_type: "transfer.success"
    )
  end
end
