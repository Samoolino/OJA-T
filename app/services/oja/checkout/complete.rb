module Oja
  module Checkout
    class Complete
      def self.call(order:, idempotency_key:, payment_intent: nil, allocation_parts: nil)
        ApplicationRecord.transaction(requires_new: true) do
          if payment_intent
            raise ArgumentError, "payment intent is not authorized" unless payment_intent.authorized?
            raise ArgumentError, "payment intent expired" if payment_intent.expired_at?
            raise ArgumentError, "payment intent amount does not match order" unless payment_intent.amount.to_d == order.total.to_d
            raise ArgumentError, "payment intent currency does not match order" unless payment_intent.currency == order.currency

            payment_intent.with_lock do
              raise ArgumentError, "payment intent already belongs to another order" if payment_intent.order_id && payment_intent.order_id != order.id

              existing = allocation_parts || Oja::OrderAllocation.where(order_id: order.id).lock.to_a
              raise ArgumentError, "no OJA allocation reservations for order" if existing.empty?

              payment_intent.update!(status: :order_pending, order: order)

              if allocation_parts
                Oja::Checkout::MaterializeAllocations.call(order: order, parts: allocation_parts)
              end

              allocations = Oja::OrderAllocation.where(order_id: order.id).lock.to_a
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

              payment_intent.update!(status: :succeeded)
            end
          else
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
        end

        order
      end
    end
  end
end
