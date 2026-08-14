module Oja
  module Fulfillment
    class Create
      def self.call(order:, vendor_reference:, mode:, idempotency_key:, tracking_reference: nil)
        raise ArgumentError, "order is required" unless order
        raise ArgumentError, "vendor_reference is required" if vendor_reference.blank?
        raise ArgumentError, "invalid fulfillment mode" unless Oja::OrderFulfillment::MODES.include?(mode.to_s)

        Oja::OrderFulfillment.find_or_create_by!(idempotency_key: idempotency_key) do |fulfillment|
          fulfillment.order_id = order.id
          fulfillment.vendor_reference = vendor_reference
          fulfillment.fulfillment_mode = mode.to_s
          fulfillment.status = "pending"
          fulfillment.tracking_reference = tracking_reference
        end
      end
    end
  end
end
