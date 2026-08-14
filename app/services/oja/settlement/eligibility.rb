module Oja
  module Settlement
    class Eligibility
      def self.call(settlement:, payment_confirmed:, fulfillment_complete:, delivery_confirmed:)
        new(
          settlement: settlement,
          payment_confirmed: payment_confirmed,
          fulfillment_complete: fulfillment_complete,
          delivery_confirmed: delivery_confirmed
        ).call
      end

      def initialize(settlement:, payment_confirmed:, fulfillment_complete:, delivery_confirmed:)
        @settlement = settlement
        @payment_confirmed = payment_confirmed
        @fulfillment_complete = fulfillment_complete
        @delivery_confirmed = delivery_confirmed
      end

      def call
        return settlement unless eligible?

        settlement.with_lock do
          settlement.reload
          return settlement if settlement.status == "eligible"
          return settlement unless settlement.status == "pending"

          settlement.update!(status: "eligible", eligible_at: Time.current)
        end

        settlement
      end

      private

      attr_reader :settlement, :payment_confirmed, :fulfillment_complete, :delivery_confirmed

      def eligible?
        payment_confirmed && fulfillment_complete && delivery_confirmed
      end
    end
  end
end
