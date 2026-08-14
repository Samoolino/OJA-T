module Oja
  module Settlement
    class ConditionalBatch
      def self.call(vendor_reference:, profile:, scope: Oja::VendorSettlement, transfer_gateway: Oja::Settlement::TransferGateway)
        settlements = scope.where(vendor_reference: vendor_reference, status: :pending).to_a
        total = settlements.sum { |s| s.net_amount.to_d }
        return :below_threshold if total < profile.minimum_payout_threshold.to_d
        return :empty if settlements.empty?

        transfer = transfer_gateway.initiate(
          amount: total,
          currency: profile.currency,
          destination: profile.payout_destination_reference,
          reference: "OJA-BATCH-#{vendor_reference}-#{Time.current.to_i}"
        )

        if transfer.success?
          settlements.each do |settlement|
            settlement.update!(status: :authorized, external_settlement_reference: transfer.reference)
          end
          :authorized
        else
          settlements.each { |settlement| settlement.update!(status: :failed) }
          :failed
        end
      end
    end
  end
end
