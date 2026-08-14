module Oja
  module Payment
    class ProviderAdapter
      Result = Data.define(:accepted, :provider_reference, :status, :raw_metadata)

      def authorize_or_charge(payment_intent:, amount:, currency:, idempotency_key:)
        raise NotImplementedError, "provider adapters must implement authorize_or_charge"
      end

      def verify_webhook(payload:, signature:)
        raise NotImplementedError, "provider adapters must implement verify_webhook"
      end

      def self.build_result(accepted:, provider_reference:, status:, raw_metadata: {})
        Result.new(accepted, provider_reference, status, raw_metadata)
      end
    end
  end
end
