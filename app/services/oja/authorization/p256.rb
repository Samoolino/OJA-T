module Oja
  module Authorization
    class P256
      REQUIRED_CLAIMS = %w[payment_intent_id receiver_id vendor_id amount currency nonce expires_at].freeze

      def self.verify!(signature:, public_key:, challenge:, claims:)
        missing = REQUIRED_CLAIMS.reject { |key| claims.key?(key) }
        raise ArgumentError, "missing signed transaction claims: #{missing.join(', ')}" if missing.any?

        raise ArgumentError, "expired authorization" if Time.at(claims.fetch("expires_at").to_i) <= Time.current

        # Cryptographic verification is deliberately isolated behind this adapter.
        # Production implementations should use a WebAuthn/FIDO2-compatible P-256
        # credential verification library and reject malformed/invalid signatures.
        verifier = OpenSSL::PKey.read(public_key)
        digest = OpenSSL::Digest::SHA256.new
        valid = verifier.verify(digest, [signature].pack("H*"), challenge)
        raise SecurityError, "invalid P-256 authorization signature" unless valid

        true
      end
    end
  end
end
