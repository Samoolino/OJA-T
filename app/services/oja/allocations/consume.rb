module Oja
  module Allocations
    class Consume
      def self.call(reservation:, idempotency_key:)
        PlanAllocation.transaction do
          reservation.lock!
          return reservation if reservation.consumed?
          raise ArgumentError, "reservation is not active" unless reservation.active?
          raise ArgumentError, "reservation expired" if reservation.expires_at <= Time.current

          allocation = reservation.allocation
          allocation.lock!

          allocation.ledger_entries.create!(
            entry_type: "consumption",
            amount: reservation.amount,
            currency: reservation.currency,
            reference_type: "AllocationReservation",
            reference_id: reservation.id.to_s,
            idempotency_key: "consumption:#{idempotency_key}"
          )

          reservation.update!(status: :consumed, consumed_at: Time.current)
          reservation
        end
      end
    end
  end
end
