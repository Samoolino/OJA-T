module Oja
  module Checkout
    class MaterializeAllocations
      def self.call(order:, parts:)
        raise ArgumentError, "order is required" unless order
        raise ArgumentError, "at least one allocation part is required" if parts.empty?

        ApplicationRecord.transaction do
          parts.map do |part|
            allocation = part.fetch(:allocation)
            reservation = part.fetch(:reservation)
            amount = part.fetch(:amount).to_d
            vendor_reference = part.fetch(:vendor_reference)
            settlement_profile = part.fetch(:settlement_profile)

            unless reservation.allocation_id == allocation.id
              raise ArgumentError, "reservation does not belong to allocation"
            end

            raise ArgumentError, "reservation is not active" unless reservation.active?
            raise ArgumentError, "reservation amount mismatch" unless reservation.amount.to_d == amount
            raise ArgumentError, "allocation currency mismatch" unless allocation.currency == order.currency
            raise ArgumentError, "settlement profile currency mismatch" unless settlement_profile.currency == order.currency

            Oja::OrderAllocation.create_or_find_by!(
              order_id: order.id,
              allocation_id: allocation.id
            ) do |order_allocation|
              order_allocation.reservation = reservation
              order_allocation.amount = amount
              order_allocation.currency = order.currency
              order_allocation.vendor_reference = vendor_reference
              order_allocation.settlement_profile = settlement_profile
            end
          end
        end
      end
    end
  end
end
