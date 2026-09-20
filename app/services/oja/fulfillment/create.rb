module Oja
  module Fulfillment
    class Create
      def self.call(order:, vendor_reference:, mode:, idempotency_key:, correlation_id:, tracking_reference: nil)
        raise ArgumentError, "order is required" unless order
        raise ArgumentError, "vendor_reference is required" if vendor_reference.blank?
        raise ArgumentError, "invalid fulfillment mode" unless Oja::OrderFulfillment::MODES.include?(mode.to_s)
        Oja::Idempotency.validate!(idempotency_key)
        raise ArgumentError, "correlation_id is required" if correlation_id.to_s.empty?

        Oja::OrderFulfillment.find_or_create_by!(idempotency_key: idempotency_key.to_s) do |fulfillment|
          fulfillment.order_id = order.id
          fulfillment.vendor_reference = vendor_reference
          fulfillment.fulfillment_mode = mode.to_s
          fulfillment.status = "pending"
          fulfillment.tracking_reference = tracking_reference
          fulfillment.correlation_id = correlation_id
        end
      end
    end
  end
end
