module Oja
  class AllocationLedgerEntry < ApplicationRecord
    self.table_name = "oja_allocation_ledger_entries"

    belongs_to :allocation, class_name: "Oja::PlanAllocation"

    ENTRY_TYPES = %w[funding allocation_issued reservation reservation_release consumption refund reversal adjustment expiry].freeze

    validates :entry_type, inclusion: { in: ENTRY_TYPES }
    validates :amount, :currency, :idempotency_key, presence: true
    validates :idempotency_key, uniqueness: true
    validates :amount, numericality: { greater_than: 0 }
  end
end
