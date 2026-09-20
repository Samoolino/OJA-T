module Oja
  module Settlement
    class RequestTransfer
      Result = Struct.new(:eligible, :reason, :settlement, keyword_init: true)

      def self.call(settlement:, payment_captured:, vendor_account_ready:, fulfillment_required:, fulfillment_confirmed:,
                    reconciliation_status:, transfer_idempotency_key:, correlation_id:)
        new(settlement:, payment_captured:, vendor_account_ready:, fulfillment_required:, fulfillment_confirmed:,
            reconciliation_status:, transfer_idempotency_key:, correlation_id:).call
      end

      def initialize(**attrs)
        @attrs = attrs
      end

      def call
        Oja::Idempotency.validate!(@attrs[:transfer_idempotency_key])
        raise ArgumentError, "correlation_id is required" if @attrs[:correlation_id].to_s.empty?

        ActiveRecord::Base.transaction do
          settlement = Oja::SettlementRecord.lock.find(@attrs[:settlement].id)
          eligibility = Oja::Settlement::Eligibility.call(
            settlement: {
              payment_captured: @attrs[:payment_captured],
              vendor_account_ready: @attrs[:vendor_account_ready],
              fulfillment_required: @attrs[:fulfillment_required],
              fulfillment_confirmed: @attrs[:fulfillment_confirmed],
              reconciliation_status: @attrs[:reconciliation_status],
              transfer_idempotency_key: @attrs[:transfer_idempotency_key]
            }
          )
          unless eligibility.eligible
            settlement.update!(status: "blocked", correlation_id: @attrs[:correlation_id].to_s) if settlement.status == "created"
            return Result.new(eligible: false, reason: eligibility.reason, settlement: settlement)
          end

          if settlement.status == "confirmed"
            return Result.new(eligible: true, reason: "settlement_already_confirmed", settlement: settlement)
          end

          settlement.status = "eligible" if settlement.status == "created"
          settlement.status = "requested"
          settlement.idempotency_key = @attrs[:transfer_idempotency_key].to_s
          settlement.correlation_id = @attrs[:correlation_id].to_s
          settlement.save!

          Result.new(eligible: true, reason: "sandbox_transfer_requested", settlement: settlement)
        end
      rescue ArgumentError, TypeError
        Result.new(eligible: false, reason: "invalid_transfer_request", settlement: @attrs[:settlement])
      end
    end
  end
end
