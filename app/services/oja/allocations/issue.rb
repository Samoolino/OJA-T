module Oja
  module Allocations
    class Issue
      def self.call(plan:, receiver:, amount:, currency:, reference:)
        raise ArgumentError, "amount must be positive" unless amount.to_d.positive?
        raise ArgumentError, "currency mismatch" unless plan.currency == currency

        PlanAllocation.transaction do
          allocation = PlanAllocation.create!(
            plan: plan,
            receiver: receiver,
            original_amount: amount,
            currency: currency,
            allocation_reference: reference,
            status: :active
          )

          AllocationLedgerEntry.create!(
            allocation: allocation,
            entry_type: "allocation_issued",
            amount: amount,
            currency: currency,
            idempotency_key: "allocation-issued:#{reference}"
          )

          allocation
        end
      end
    end
  end
end
