require "rails_helper"

RSpec.describe Oja::Checkout::Complete do
  it "materializes, consumes, and settles multiple order allocations for an authorized payment intent" do
    order = instance_double("Spree::Order", id: 42, total: 100_000.to_d, currency: "NGN")
    payment_intent = instance_double(
      Oja::PaymentIntent,
      authorized?: true,
      expired_at?: false,
      amount: 100_000.to_d,
      currency: "NGN",
      order_id: nil
    )
    reservation_a = instance_double(Oja::AllocationReservation, consumed?: false)
    reservation_b = instance_double(Oja::AllocationReservation, consumed?: false)
    allocation_a = instance_double(Oja::OrderAllocation,
      reservation: reservation_a,
      vendor_reference: "vendor-a",
      amount: 60_000.to_d,
      currency: "NGN",
      settlement_profile: instance_double(Oja::VendorSettlementProfile))
    allocation_b = instance_double(Oja::OrderAllocation,
      reservation: reservation_b,
      vendor_reference: "vendor-b",
      amount: 40_000.to_d,
      currency: "NGN",
      settlement_profile: instance_double(Oja::VendorSettlementProfile))
    part_a = { allocation: instance_double(Oja::PlanAllocation, id: 1, currency: "NGN"), reservation: reservation_a, amount: 60_000, vendor_reference: "vendor-a", settlement_profile: allocation_a.settlement_profile }
    part_b = { allocation: instance_double(Oja::PlanAllocation, id: 2, currency: "NGN"), reservation: reservation_b, amount: 40_000, vendor_reference: "vendor-b", settlement_profile: allocation_b.settlement_profile }

    allow(ApplicationRecord).to receive(:transaction).and_yield
    allow(payment_intent).to receive(:with_lock).and_yield
    allow(payment_intent).to receive(:order_id).and_return(nil)
    expect(payment_intent).to receive(:update!).with(status: :order_pending, order: order)
    expect(payment_intent).to receive(:update!).with(status: :succeeded)
    expect(Oja::Checkout::MaterializeAllocations).to receive(:call).with(order: order, parts: [part_a, part_b])
    expect(Oja::OrderAllocation).to receive(:where).with(order_id: 42).and_return(double(lock: [allocation_a, allocation_b]))
    expect(Oja::Allocations::Consume).to receive(:call).twice
    expect(Oja::Settlement::Create).to receive(:call).twice

    expect(described_class.call(
      order: order,
      idempotency_key: "pi-1",
      payment_intent: payment_intent,
      allocation_parts: [part_a, part_b]
    )).to eq(order)
  end

  it "rolls back the checkout transaction when payment-intent completion fails" do
    order = instance_double("Spree::Order", id: 42, total: 100_000.to_d, currency: "NGN")
    payment_intent = instance_double(Oja::PaymentIntent,
      authorized?: false,
      expired_at?: false,
      amount: 100_000.to_d,
      currency: "NGN")

    expect(ApplicationRecord).to receive(:transaction).with(requires_new: true).and_yield
    expect {
      described_class.call(order: order, idempotency_key: "pi-2", payment_intent: payment_intent, allocation_parts: [])
    }.to raise_error(ArgumentError, "payment intent is not authorized")
  end
end
