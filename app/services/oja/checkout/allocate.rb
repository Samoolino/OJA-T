module Oja
  module Checkout
    class Allocate
      AllocationPart = Data.define(:allocation, :amount, :reservation)

      def self.call(receiver:, total:, currency:, idempotency_key:, order_id: nil, expires_at: 15.minutes.from_now)
        raise ArgumentError, "total must be positive" unless total.to_d.positive?

        allocations = receiver.allocations.active.order(:created_at, :id).to_a
        remaining = total.to_d
        reservations = []

        ApplicationRecord.transaction do
          allocations.each do |allocation|
            break if remaining <= 0
            next unless allocation.currency == currency

            available = allocation.available_amount.to_d - allocation.reservations.active.where("expires_at > ?", Time.current).sum(:amount).to_d
            next unless available.positive?

            amount = [available, remaining].min
            reservation = Oja::Allocations::Reserve.call(
              allocation: allocation,
              amount: amount,
              currency: currency,
              idempotency_key: "#{idempotency_key}:#{allocation.id}",
              expires_at: expires_at,
              order_id: order_id
            )
            reservations << AllocationPart.new(allocation, amount, reservation)
            remaining -= amount
          end

          raise ArgumentError, "insufficient eligible allocation" if remaining.positive?
        end

        reservations
      end
    end
  end
end
