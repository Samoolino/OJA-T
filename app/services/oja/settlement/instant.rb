module Oja
  module Settlement
    class Instant
      def self.call(settlement:, profile:, transfer_gateway: Oja::Settlement::TransferGateway)
        transfer = transfer_gateway.initiate(
          amount: settlement.net_amount,
          currency: settlement.currency,
          destination: profile.payout_destination_reference,
          reference: "OJA-SETTLEMENT-#{settlement.id}"
        )

        if transfer.success?
          settlement.update!(status: :authorized, external_settlement_reference: transfer.reference)
        else
          settlement.update!(status: :failed)
        end
        settlement
      end
    end
  end
end
