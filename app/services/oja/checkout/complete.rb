module Oja
  module Checkout
    class Complete
      def self.call(order:, idempotency_key:)
        ApplicationRecord.transaction do
          allocations = Oja::OrderAllocation.where(order_id: order.id).lock.to_a
          raise ArgumentError, "no OJA allocation reservations for order" if allocations.empty?

          allocations.each_with_index do |order_allocation, index|
            Oja::Allocations::Consume.call(
              reservation: order_allocation.reservation,
              idempotency_key: "#{idempotency_key}:#{index}"
            )
          end

          allocations.each do |order_allocation|
            Oja::Settlement::Create.call(
              order_allocation: order_allocation,
              vendor_reference: order_allocation.vendor_reference,
              gross_amount: order_allocation.amount,
              currency: order_allocation.currency,
              profile: order_allocation.settlement_profile
            )
          end
        end

        order
      end
    end
  end
end
