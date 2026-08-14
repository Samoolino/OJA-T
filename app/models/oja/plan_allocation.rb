module Oja
  class PlanAllocation < ApplicationRecord
    self.table_name = "oja_plan_allocations"

    belongs_to :plan, class_name: "Oja::Plan"
    belongs_to :receiver, class_name: "Oja::Receiver"
    has_many :ledger_entries, class_name: "Oja::AllocationLedgerEntry", dependent: :restrict_with_exception
    has_many :reservations, class_name: "Oja::AllocationReservation", dependent: :restrict_with_exception

    enum :status, { pending: "pending", active: "active", suspended: "suspended", expired: "expired", exhausted: "exhausted", revoked: "revoked" }, default: :pending

    validates :original_amount, :currency, presence: true
    validates :original_amount, numericality: { greater_than: 0 }
    validates :allocation_reference, presence: true, uniqueness: true

    def available_amount
      credited = ledger_entries.where(entry_type: %w[funding allocation_issued refund reversal adjustment]).sum(:amount)
      debited = ledger_entries.where(entry_type: %w[consumption reservation expiry]).sum(:amount)
      credited - debited
    end
  end
end
