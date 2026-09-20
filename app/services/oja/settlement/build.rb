module Oja
  module Settlement
    class Build
      def self.call(order_id:, vendor_reference:, currency:, gross_amount_minor:, platform_fee_minor:, allocation_id:, correlation_id:, idempotency_key:)
        new(order_id:, vendor_reference:, currency:, gross_amount_minor:, platform_fee_minor:, allocation_id:, correlation_id:, idempotency_key:).call
      end

      def initialize(order_id:, vendor_reference:, currency:, gross_amount_minor:, platform_fee_minor:, allocation_id:, correlation_id:, idempotency_key:)
        @order_id = order_id
        @vendor_reference = vendor_reference.to_s
        @currency = currency.to_s.upcase
        @gross = Integer(gross_amount_minor)
        @fee = Integer(platform_fee_minor)
        @allocation_id = allocation_id
        @correlation_id = correlation_id.to_s
        @idempotency_key = idempotency_key
      end

      def call
        Oja::Idempotency.validate!(@idempotency_key)
        raise ArgumentError, "correlation_id is required" if @correlation_id.empty?
        raise ArgumentError, "invalid settlement amounts" if @gross.negative? || @fee.negative? || @fee > @gross

        settlement = Oja::SettlementRecord.find_or_create_by!(idempotency_key: @idempotency_key.to_s) do |record|
          record.order_id = @order_id
          record.vendor_reference = @vendor_reference
          record.currency = @currency
          record.gross_amount_minor = @gross
          record.platform_fee_minor = @fee
          record.net_amount_minor = @gross - @fee
          record.allocation_id = @allocation_id
          record.correlation_id = @correlation_id
          record.status = "created"
        end

        settlement
      end
    end
  end
end
