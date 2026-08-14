module Oja
  module Settlement
    class Create
      def self.call(order_allocation:, vendor_reference:, gross_amount:, currency:, profile:)
        platform_fee = gross_amount.to_d * profile.commission_rate.to_d / 100
        settlement = Oja::VendorSettlement.create!(
          order_allocation: order_allocation,
          vendor_reference: vendor_reference,
          gross_amount: gross_amount,
          platform_fee: platform_fee,
          net_amount: gross_amount.to_d - platform_fee,
          currency: currency,
          status: :pending
        )

        Oja::Settlement::Route.call(settlement: settlement, profile: profile)
        settlement
      end
    end
  end
end
