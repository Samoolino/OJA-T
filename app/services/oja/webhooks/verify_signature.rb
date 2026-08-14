require "openssl"

module Oja
  module Webhooks
    class VerifySignature
      def self.call(payload:, signature:, secret: ENV.fetch("OJA_WEBHOOK_SECRET"))
        expected = OpenSSL::HMAC.hexdigest("SHA256", secret, payload.to_s)
        return true if signature.present? && ActiveSupport::SecurityUtils.secure_compare(signature, expected)

        raise ArgumentError, "invalid webhook signature"
      end
    end
  end
end
