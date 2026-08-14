require "spec_helper"

RSpec.describe Oja::Fulfillment::Create do
  it "creates one vendor fulfillment per idempotency key" do
    order = instance_double("Spree::Order", id: 101)
    fulfillment = instance_double(Oja::OrderFulfillment)

    allow(Oja::OrderFulfillment).to receive(:find_or_create_by!).with(idempotency_key: "fulfill-1").and_yield(fulfillment).and_return(fulfillment)
    allow(fulfillment).to receive(:order_id=)
    allow(fulfillment).to receive(:vendor_reference=)
    allow(fulfillment).to receive(:fulfillment_mode=)
    allow(fulfillment).to receive(:status=)
    allow(fulfillment).to receive(:tracking_reference=)

    expect(described_class.call(
      order: order,
      vendor_reference: "vendor-1",
      mode: :courier,
      idempotency_key: "fulfill-1"
    )).to eq(fulfillment)

    expect(fulfillment).to have_received(:order_id=).with(101)
    expect(fulfillment).to have_received(:vendor_reference=).with("vendor-1")
    expect(fulfillment).to have_received(:fulfillment_mode=).with("courier")
    expect(fulfillment).to have_received(:status=).with("pending")
  end

  it "rejects unsupported fulfillment modes" do
    expect {
      described_class.call(
        order: instance_double("Spree::Order", id: 101),
        vendor_reference: "vendor-1",
        mode: :unsupported,
        idempotency_key: "fulfill-2"
      )
    }.to raise_error(ArgumentError, "invalid fulfillment mode")
  end
end
