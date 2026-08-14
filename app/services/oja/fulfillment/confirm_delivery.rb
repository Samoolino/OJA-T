module Oja
  module Fulfillment
    class ConfirmDelivery
      def self.call(fulfillment:, confirmation_reference:)
        return fulfillment if fulfillment.delivered?

        ApplicationRecord.transaction do
          fulfillment.with_lock do
            return fulfillment if fulfillment.delivered?

            fulfillment.update!(
              status: "delivered",
              delivered_at: Time.current,
              delivery_confirmed_at: Time.current,
              tracking_reference: confirmation_reference.presence || fulfillment.tracking_reference
            )
          end

          Oja::VendorSettlement.where(
            order_allocation_id: Oja::OrderAllocation.where(
              order_id: fulfillment.order_id,
              vendor_reference: fulfillment.vendor_reference
            ).select(:id),
            status: :pending
          ).find_each do |settlement|
            profile = settlement.order_allocation.settlement_profile
            settlement.update!(status: :payable)
            Oja::Settlement::Route.call(settlement: settlement, profile: profile)
          end
        end

        fulfillment
      end
    end
  end
end
