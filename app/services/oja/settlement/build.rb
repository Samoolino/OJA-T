module Oja
  class Settlement
    class Build
      def self.call(order:, vendor_reference:, gross_amount:, platform_fee:, currency:, settlement_reference:, strategy: "delayed", eligible_at: nil)
        new(
          order: order,
          vendor_reference: vendor_reference,
          gross_amount: gross_amount,
          platform_fee: platform_fee,
          currency: currency,
          settlement_reference: settlement_reference,
          strategy: strategy,
          eligible_at: eligible_at
        ).call
      end

      def initialize(order:, vendor_reference:, gross_amount:, platform_fee:, currency:, settlement_reference:, strategy:, eligible_at:)
        @order = order
        @vendor_reference = vendor_reference
        @gross_amount = gross_amount
        @platform_fee = platform_fee
        @currency = currency
        @settlement_reference = settlement_reference
        @strategy = strategy
        @eligible_at = eligible_at
      end

      def call
        Settlement.create_with(
          gross_amount: gross_amount,
          platform_fee: platform_fee,
          net_amount: gross_amount - platform_fee,
          currency: currency,
          status: strategy == "instant" ? "eligible" : "pending",
          settlement_strategy: strategy,
          eligible_at: eligible_at
        ).find_or_create_by!(
          settlement_reference: settlement_reference
        ) do |settlement|
          settlement.order = order
          settlement.vendor_reference = vendor_reference
        end
      end

      private

      attr_reader :order, :vendor_reference, :gross_amount, :platform_fee,
                  :currency, :settlement_reference, :strategy, :eligible_at
    end
  end
end
