module Oja
  module Payment
    class RefundAllocation
      Result = Struct.new(:refunded, :reason, :entry, keyword_init: true)

      def self.call(allocation:, amount_minor:, idempotency_key:, correlation_id:, metadata: {})
        new(allocation:, amount_minor:, idempotency_key:, correlation_id:, metadata:).call
      end

      def initialize(allocation:, amount_minor:, idempotency_key:, correlation_id:, metadata:)
        @allocation, @amount = allocation, Integer(amount_minor)
        @idempotency_key, @correlation_id, @metadata = idempotency_key, correlation_id, metadata
      end

      def call
        Oja::Idempotency.validate!(@idempotency_key)
        raise ArgumentError, "correlation_id is required" if @correlation_id.to_s.empty?
        raise ArgumentError, "amount must be positive" unless @amount.positive?

        entry = Oja::Allocation::LedgerOperation.call(
          allocation: @allocation,
          entry_type: "reverse",
          amount_minor: @amount,
          idempotency_key: @idempotency_key,
          correlation_id: @correlation_id,
          metadata: @metadata.merge("refund" => true)
        )

        Result.new(refunded: true, reason: "refund_recorded", entry: entry)
      rescue ArgumentError, TypeError
        Result.new(refunded: false, reason: "refund_rejected", entry: nil)
      end
    end
  end
end
