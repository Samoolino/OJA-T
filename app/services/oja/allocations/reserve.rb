module Oja
  module Allocations
    class Reserve
      def self.call(allocation:, amount:, currency:, idempotency_key:, expires_at:, order_id: nil)
        raise ArgumentError, "amount must be positive" unless amount.to_d.positive?
        raise ArgumentError, "currency mismatch" unless allocation.currency == currency

        PlanAllocation.transaction do
          allocation.lock!

          existing = AllocationReservation.find_by(idempotency_key: idempotency_key)
          return existing if existing

          active_reserved = allocation.reservations.active.where("expires_at > ?", Time.current).sum(:amount)
          consumed = allocation.ledger_entries.where(entry_type: "consumption").sum(:amount)
          issued = allocation.ledger_entries.where(entry_type: %w[allocation_issued funding refund reversal adjustment]).sum(:amount)
          available = issued - consumed - active_reserved

          raise ArgumentError, "insufficient allocation" if amount.to_d > available

          reservation = allocation.reservations.create!(
            amount: amount,
            currency: currency,
            status: :active,
            expires_at: expires_at,
            idempotency_key: idempotency_key,
            order_id: order_id
          )

          allocation.ledger_entries.create!(
            entry_type: "reservation",
            amount: amount,
            currency: currency,
            reference_type: "AllocationReservation",
            reference_id: reservation.id.to_s,
            idempotency_key: "reservation:#{idempotency_key}"
          )

          reservation
        end
      end
    end
  end
end
