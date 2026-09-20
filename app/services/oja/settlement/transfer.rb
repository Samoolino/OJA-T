module Oja
  module Settlement
    class Transfer
      def self.call(settlement:, payment_captured:, vendor_account_ready:, fulfillment_required:, fulfillment_confirmed:, reconciliation_status:, transfer_idempotency_key:)
        raise ArgumentError, "settlement is required" unless settlement
        Oja::Idempotency.validate!(transfer_idempotency_key)
        eligibility = Oja::Settlement::Eligibility.call(
          settlement: {
            payment_captured: payment_captured,
            vendor_account_ready: vendor_account_ready,
            fulfillment_required: fulfillment_required,
            fulfillment_confirmed: fulfillment_confirmed,
            reconciliation_status: reconciliation_status,
            transfer_idempotency_key: transfer_idempotency_key
          }
        )
        raise ArgumentError, eligibility.reason unless eligibility.eligible
        ActiveRecord::Base.transaction do
          row = Oja::SettlementRecord.lock.find(settlement.id)
          return row if row.status == "requested" || row.status == "confirmed"
          row.status = "requested"
          row.idempotency_key = transfer_idempotency_key.to_s
          row.save!
          row
        end
      end
    end
  end
end
