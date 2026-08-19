module Oja
  module Payment
    class Authorize
      P256 = "biometric_p256".freeze

      def self.call(payment_intent:, signature:, credential_reference:, verifier:)
        raise ArgumentError, "payment intent expired" if payment_intent.expired_at?
        raise ArgumentError, "unsupported authorization method" unless payment_intent.authorization_method == P256
        raise ArgumentError, "signature is required" if signature.to_s.empty?
        raise ArgumentError, "credential reference is required" if credential_reference.to_s.empty?

        payload = [
          "OJA-PAYMENT",
          payment_intent.id,
          payment_intent.amount.to_d.to_s("F"),
          payment_intent.currency,
          payment_intent.nonce,
          payment_intent.expires_at.to_i,
          payment_intent.idempotency_key
        ].join(":")

        valid = verifier.verify(
          signature: signature,
          credential_reference: credential_reference,
          payload: payload
        )
        raise ArgumentError, "authorization signature invalid" unless valid

        payment_intent.with_lock do
          return payment_intent if payment_intent.authorized?
          raise ArgumentError, "payment intent cannot be authorized from #{payment_intent.status}" unless payment_intent.pending? || payment_intent.requires_authorization?

          payment_intent.update!(
            status: :authorized,
            authorized_at: Time.current
          )
        end

        payment_intent
      end
    end
  end
end
