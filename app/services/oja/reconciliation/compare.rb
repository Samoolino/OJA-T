module Oja
  module Reconciliation
    class Compare
      Result = Struct.new(:record, :status, keyword_init: true)

      def self.call(provider:, provider_event_id:, payment_reference:, order_reference:, expected_currency:, expected_amount_minor:, observed_currency:, observed_amount_minor:, correlation_id:)
        new(provider:, provider_event_id:, payment_reference:, order_reference:, expected_currency:, expected_amount_minor:, observed_currency:, observed_amount_minor:, correlation_id:).call
      end

      def initialize(**attrs)
        @attrs = attrs
      end

      def call
        status =
          if @attrs[:expected_currency].to_s.upcase != @attrs[:observed_currency].to_s.upcase
            "CURRENCY_MISMATCH"
          elsif Integer(@attrs[:expected_amount_minor]) != Integer(@attrs[:observed_amount_minor])
            "AMOUNT_MISMATCH"
          else
            "MATCHED"
          end

        record = Oja::ReconciliationRecord.find_or_create_by!(
          provider: @attrs[:provider].to_s,
          provider_event_id: @attrs[:provider_event_id].to_s
        ) do |r|
          r.payment_reference = @attrs[:payment_reference]
          r.order_reference = @attrs[:order_reference]
          r.status = status
          r.expected_currency = @attrs[:expected_currency].to_s.upcase
          r.expected_amount_minor = Integer(@attrs[:expected_amount_minor])
          r.observed_currency = @attrs[:observed_currency].to_s.upcase
          r.observed_amount_minor = Integer(@attrs[:observed_amount_minor])
          r.correlation_id = @attrs[:correlation_id]
          r.resolved_at = Time.current if status == "MATCHED"
        end
        Result.new(record:, status:)
      end
    end
  end
end
