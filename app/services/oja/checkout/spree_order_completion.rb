module Oja
  module Checkout
    class SpreeOrderCompletion
      def self.call(order:, idempotency_key:)
        Oja::Checkout::Complete.call(order: order, idempotency_key: idempotency_key)
      end
    end
  end
end
