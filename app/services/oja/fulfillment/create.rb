module Oja
  module Fulfillment
    class Create
      def self.call(order:, idempotency_key:)
        ApplicationRecord.transaction do
          Oja::OrderAllocation.where(order_id: order.id).find_each.with_index do |order_allocation, index|
            profile = Oja::VendorFulfillmentProfile.find_by(vendor_reference: order_allocation.vendor_reference)
            mode = profile&.fulfillment_mode || "courier"

            Oja::OrderFulfillment.create_or_find_by!(
              order_id: order.id,
              vendor_reference: order_allocation.vendor_reference
            ) do |fulfillment|
              fulfillment.fulfillment_mode = mode
              fulfillment.status = mode == "digital" ? "processing" : "pending"
              fulfillment.idempotency_key = "#{idempotency_key}:fulfillment:#{index}"
            end
          end
        end
      end
    end
  end
end
