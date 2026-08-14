require "rails_helper"

RSpec.describe Oja::Fulfillment::ConfirmDelivery do
  describe ".call" do
    it "is idempotent for an already delivered fulfillment" do
      fulfillment = instance_double(Oja::OrderFulfillment, delivered?: true)

      expect(described_class.call(fulfillment: fulfillment, confirmation_reference: "POD-1")).to eq(fulfillment)
    end
  end
end
