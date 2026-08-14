require "rails_helper"

RSpec.describe Oja::Fulfillment::Create do
  it "creates one vendor fulfillment per order allocation" do
    order = instance_double("Spree::Order", id: 101)
    order_allocation = instance_double(Oja::OrderAllocation, vendor_reference: "vendor-1")
    profile = instance_double(Oja::VendorFulfillmentProfile, fulfillment_mode: "courier")
    fulfillment = instance_double(Oja::OrderFulfillment)
    allocations = double("OrderAllocationsRelation")

    allow(ApplicationRecord).to receive(:transaction).and_yield
    allow(Oja::OrderAllocation).to receive(:where).with(order_id: 101).and_return(allocations)
    allow(allocations).to receive(:each).and_yield(order_allocation)
    allow(Oja::VendorFulfillmentProfile).to receive(:find_by).with(vendor_reference: "vendor-1").and_return(profile)
    allow(Oja::OrderFulfillment).to receive(:create_or_find_by!).with(
      order_id: 101,
      vendor_reference: "vendor-1"
    ).and_yield(fulfillment).and_return(fulfillment)

    allow(fulfillment).to receive(:fulfillment_mode=)
    allow(fulfillment).to receive(:status=)
    allow(fulfillment).to receive(:idempotency_key=)

    expect(described_class.call(order: order, idempotency_key: "fulfill-1")).to eq(fulfillment)
    expect(fulfillment).to have_received(:fulfillment_mode=).with("courier")
    expect(fulfillment).to have_received(:status=).with("pending")
    expect(fulfillment).to have_received(:idempotency_key=).with("fulfill-1:fulfillment:0")
  end

  it "rejects unsupported fulfillment modes" do
    order = instance_double("Spree::Order", id: 101)
    order_allocation = instance_double(Oja::OrderAllocation, vendor_reference: "vendor-1")
    profile = instance_double(Oja::VendorFulfillmentProfile, fulfillment_mode: "unsupported")
    allocations = double("OrderAllocationsRelation")

    allow(ApplicationRecord).to receive(:transaction).and_yield
    allow(Oja::OrderAllocation).to receive(:where).with(order_id: 101).and_return(allocations)
    allow(allocations).to receive(:each).and_yield(order_allocation)
    allow(Oja::VendorFulfillmentProfile).to receive(:find_by).with(vendor_reference: "vendor-1").and_return(profile)

    expect {
      described_class.call(order: order, idempotency_key: "fulfill-2")
    }.to raise_error(ArgumentError, "invalid fulfillment mode")
  end
end
