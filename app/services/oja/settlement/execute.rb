module Oja
  module Settlement
    class Execute
      def self.call(settlement:, transfer_gateway:)
        ApplicationRecord.transaction do
          settlement.with_lock do
            return settlement if settlement.paid? || settlement.authorized?
            raise ArgumentError, "settlement is not payable" unless settlement.payable? || settlement.pending?

            transfer = transfer_gateway.initiate(
              amount: settlement.net_amount,
              currency: settlement.currency,
              destination_reference: settlement.destination_reference,
              reference: "OJA-SETTLEMENT-#{settlement.id}"
            )

            if transfer.success?
              settlement.update!(status: :authorized, payout_reference: transfer.reference)
            else
              settlement.update!(status: :failed)
            end
          end
        end
      end
    end
  end
end
