module Oja
  module Settlement
    class Create
      def self.call(order_allocation:, vendor_reference:, gross_amount:, currency:, profile:)
        platform_fee = (gross_amount.to_d * profile.commission_rate.to_d / 100).round(2)
        fulfillment = Oja::OrderFulfillment.find_by(
          order_id: order_allocation.order_id,
          vendor_reference: vendor_reference
        )

        delivery_gate = profile.settlement_requires_delivery_confirmation? && !fulfillment&.delivered?
        status = delivery_gate ? :pending : :payable

        settlement = Oja::VendorSettlement.create!(
          order_allocation: order_allocation,
          vendor_reference: vendor_reference,
          destination_reference: profile.payout_destination_reference,
          gross_amount: gross_amount,
          platform_fee: platform_fee,
          net_amount: gross_amount.to_d - platform_fee,
          currency: currency,
          status: status
        )

        Oja::Settlement::Route.call(settlement: settlement, profile: profile) unless delivery_gate
        settlement
      end
    end
  end
end
