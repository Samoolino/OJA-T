module Oja
  module Checkout
    class Complete
      def self.call(order:)
        ApplicationRecord.transaction do
          allocations = Oja::OrderAllocation.where(order_id: order.id).lock.to_a
          raise ArgumentError, "no OJA allocation reservations for order" if allocations.empty?

          Oja::Allocations::Consume.call(order: order)
          Oja::Settlement::Create.call(order: order)
        end

        order
      end
    end
  end
end
