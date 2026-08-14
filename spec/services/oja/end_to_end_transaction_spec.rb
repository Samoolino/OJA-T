require "rails_helper"

RSpec.describe "OJA end-to-end transaction lifecycle" do
  it "carries a receiver's multi-plan funding through authorization, order, fulfillment, delivery and settlement reconciliation" do
    order = instance_double("Spree::Order", id: 501, total: 100_000.to_d, currency: "NGN")
    payment_intent = instance_double(Oja::PaymentIntent, id: 9001, amount: 100_000.to_d, currency: "NGN", authorized?: true, expired_at?: false, order_id: nil)

    allocation_a = instance_double(Oja::PlanAllocation, id: 11, currency: "NGN")
    allocation_b = instance_double(Oja::PlanAllocation, id: 12, currency: "NGN")
    reservation_a = instance_double(Oja::AllocationReservation, allocation_id: 11, active?: true, amount: 60_000.to_d, consumed?: false)
    reservation_b = instance_double(Oja::AllocationReservation, allocation_id: 12, active?: true, amount: 40_000.to_d, consumed?: false)
    settlement_profile_a = instance_double(Oja::VendorSettlementProfile, currency: "NGN")
    settlement_profile_b = instance_double(Oja::VendorSettlementProfile, currency: "NGN")
    fulfillment_profile_a = instance_double(Oja::VendorFulfillmentProfile, fulfillment_mode: "courier")
    fulfillment_profile_b = instance_double(Oja::VendorFulfillmentProfile, fulfillment_mode: "courier")

    order_allocation_a = instance_double(Oja::OrderAllocation,
      order_id: 501, reservation: reservation_a, amount: 60_000.to_d, currency: "NGN",
      vendor_reference: "vendor-a", settlement_profile: settlement_profile_a)
    order_allocation_b = instance_double(Oja::OrderAllocation,
      order_id: 501, reservation: reservation_b, amount: 40_000.to_d, currency: "NGN",
      vendor_reference: "vendor-b", settlement_profile: settlement_profile_b)

    parts = [
      { allocation: allocation_a, reservation: reservation_a, amount: 60_000, vendor_reference: "vendor-a", settlement_profile: settlement_profile_a },
      { allocation: allocation_b, reservation: reservation_b, amount: 40_000, vendor_reference: "vendor-b", settlement_profile: settlement_profile_b }
    ]

    allow(ApplicationRecord).to receive(:transaction).and_yield
    allow(payment_intent).to receive(:with_lock).and_yield
    expect(payment_intent).to receive(:update!).with(status: :order_pending, order: order)
    expect(payment_intent).to receive(:update!).with(status: :succeeded)

    allow(Oja::Checkout::MaterializeAllocations).to receive(:call).with(order: order, parts: parts)
    allow(Oja::OrderAllocation).to receive(:where).with(order_id: 501).and_return(double(lock: [order_allocation_a, order_allocation_b]))

    expect(Oja::Allocations::Consume).to receive(:call).with(reservation: reservation_a, idempotency_key: "checkout-1:0")
    expect(Oja::Allocations::Consume).to receive(:call).with(reservation: reservation_b, idempotency_key: "checkout-1:1")
    expect(Oja::Settlement::Create).to receive(:call).with(order_allocation: order_allocation_a, vendor_reference: "vendor-a", gross_amount: 60_000.to_d, currency: "NGN", profile: settlement_profile_a)
    expect(Oja::Settlement::Create).to receive(:call).with(order_allocation: order_allocation_b, vendor_reference: "vendor-b", gross_amount: 40_000.to_d, currency: "NGN", profile: settlement_profile_b)

    Oja::Checkout::Complete.call(
      order: order,
      idempotency_key: "checkout-1",
      payment_intent: payment_intent,
      allocation_parts: parts
    )

    fulfillment_a = instance_double(Oja::OrderFulfillment)
    fulfillment_b = instance_double(Oja::OrderFulfillment)
    allow(fulfillment_a).to receive(:fulfillment_mode=)
    allow(fulfillment_a).to receive(:status=)
    allow(fulfillment_a).to receive(:idempotency_key=)
    allow(fulfillment_b).to receive(:fulfillment_mode=)
    allow(fulfillment_b).to receive(:status=)
    allow(fulfillment_b).to receive(:idempotency_key=)

    allow(Oja::OrderAllocation).to receive(:where).with(order_id: 501).and_return([order_allocation_a, order_allocation_b])
    allow(Oja::VendorFulfillmentProfile).to receive(:find_by).with(vendor_reference: "vendor-a").and_return(fulfillment_profile_a)
    allow(Oja::VendorFulfillmentProfile).to receive(:find_by).with(vendor_reference: "vendor-b").and_return(fulfillment_profile_b)
    expect(Oja::OrderFulfillment).to receive(:create_or_find_by!).with(order_id: 501, vendor_reference: "vendor-a").and_yield(fulfillment_a).and_return(fulfillment_a)
    expect(Oja::OrderFulfillment).to receive(:create_or_find_by!).with(order_id: 501, vendor_reference: "vendor-b").and_yield(fulfillment_b).and_return(fulfillment_b)

    Oja::Fulfillment::Create.call(order: order, idempotency_key: "fulfill-1")

    allow(fulfillment_a).to receive(:delivered?).and_return(false)
    allow(fulfillment_a).to receive(:order_id).and_return(501)
    allow(fulfillment_a).to receive(:vendor_reference).and_return("vendor-a")
    allow(fulfillment_a).to receive(:with_lock).and_yield
    allow(fulfillment_a).to receive(:update!).with(hash_including(status: "delivered"))

    settlement_a = instance_double(Oja::VendorSettlement, order_allocation: order_allocation_a, paid?: false, failed?: false)
    settlement_relation = double("PendingSettlements")
    allocation_scope = double("OrderAllocationScope", select: [101])
    allow(Oja::OrderAllocation).to receive(:where).with(order_id: 501, vendor_reference: "vendor-a").and_return(allocation_scope)
    allow(Oja::VendorSettlement).to receive(:where).with(order_allocation_id: [101], status: :pending).and_return(settlement_relation)
    allow(settlement_relation).to receive(:find_each).and_yield(settlement_a)
    allow(settlement_a).to receive(:update!).with(status: :payable)
    expect(Oja::Settlement::Route).to receive(:call).with(settlement: settlement_a, profile: settlement_profile_a)

    Oja::Fulfillment::ConfirmDelivery.call(fulfillment: fulfillment_a, confirmation_reference: "DEL-501-A")

    allow(Oja::VendorSettlement).to receive(:find_by!).with(payout_reference: "payout-a").and_return(settlement_a)
    allow(settlement_a).to receive(:with_lock).and_yield
    expect(settlement_a).to receive(:update!).with(status: :paid, settled_at: kind_of(Time))

    Oja::Settlement::Reconcile.call(external_reference: "payout-a", event_type: "transfer.success")
  end
end
