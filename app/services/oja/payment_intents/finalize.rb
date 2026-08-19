module Oja
  module PaymentIntents
    class Finalize
      def self.call(payment_intent:, authorization:) 
        raise ArgumentError, "payment intent expired" if payment_intent.expired_at?
        raise ArgumentError, "payment intent is not awaiting authorization" unless payment_intent.pending? || payment_intent.requires_authorization?

        payment_intent.with_lock do
          payment_intent.update!(
            status: :authorized,
            challenge: authorization.fetch(:challenge)
          )
        end

        payment_intent
      end
    end
  end
end
