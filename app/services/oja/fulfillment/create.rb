module Oja
  module Fulfillment
    class Create
      SUPPORTED_MODES = Oja::VendorFulfillmentProfile::FULFILLMENT_MODES.freeze

      def self.call(order:, idempotency_key:)
        ApplicationRecord.transaction do
          Oja::OrderAllocation.where(order_id: order.id).each_with_index do |order_allocation, index|
            profile = Oja::VendorFulfillmentProfile.find_by(vendor_reference: order_allocation.vendor_reference)
            mode = profile&.fulfillment_mode || "courier"
            raise ArgumentError, "invalid fulfillment mode" unless SUPPORTED_MODES.include?(mode)

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
