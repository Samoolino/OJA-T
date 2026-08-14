module Oja
  module Settlement
    class ConditionalBatch
      def self.call(vendor_reference:, profile:, scope: Oja::VendorSettlement, transfer_gateway:)
        settlements_scope = scope.where(vendor_reference: vendor_reference, status: :payable)
        settlements = if settlements_scope.respond_to?(:order)
          settlements_scope.order(:id).lock.to_a
        else
          settlements_scope.to_a
        end

        return :empty if settlements.empty?

        total = settlements.sum { |settlement| settlement.net_amount.to_d }
        return :below_threshold if total < profile.minimum_payout_threshold.to_d

        transfer = transfer_gateway.initiate(
          amount: total,
          currency: settlements.first.currency,
          destination_reference: profile.payout_destination_reference,
          reference: "OJA-BATCH-#{vendor_reference}-#{settlements.first.id}-#{settlements.last.id}"
        )

        ApplicationRecord.transaction do
          if transfer.success?
            settlements.each do |settlement|
              settlement.update!(status: :authorized, payout_reference: transfer.reference)
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
end
