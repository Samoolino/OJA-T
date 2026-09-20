module Oja
  module Settlement
    class Eligibility
      Result = Struct.new(:eligible, :reason, keyword_init: true)
      def self.call(settlement:)
        new(settlement:).call
      end
      def initialize(settlement:)
        @settlement = settlement || {}
      end
      def call
        return Result.new(eligible: false, reason: "settlement_missing") if @settlement.empty?
        return Result.new(eligible: false, reason: "payment_not_captured") unless @settlement[:payment_captured] == true
        return Result.new(eligible: false, reason: "vendor_account_not_ready") unless @settlement[:vendor_account_ready] == true
        return Result.new(eligible: false, reason: "fulfillment_not_confirmed") if @settlement[:fulfillment_required] && @settlement[:fulfillment_confirmed] != true
        return Result.new(eligible: false, reason: "reconciliation_exception") if @settlement[:reconciliation_exception] == true
        return Result.new(eligible: false, reason: "transfer_idempotency_key_missing") if @settlement[:transfer_idempotency_key].to_s.empty?
        Result.new(eligible: true, reason: "settlement_eligible")
      end
    end
  end
end
