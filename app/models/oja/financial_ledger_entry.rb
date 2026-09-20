module Oja
  class FinancialLedgerEntry < ActiveRecord::Base
    self.table_name = "oja_financial_ledger_entries"

    belongs_to :allocation, class_name: "Oja::PlanAllocation", foreign_key: :allocation_id, inverse_of: :ledger_entries

    ENTRY_TYPES = %w[fund reserve consume release reverse].freeze

    validates :operation_id, :idempotency_key, :entry_type, :currency, :correlation_id, presence: true
    validates :amount_minor, numericality: { greater_than: 0 }
    validates :entry_type, inclusion: { in: ENTRY_TYPES }

    before_update { raise ActiveRecord::ReadOnlyRecord, "financial ledger entries are immutable" }
    before_destroy { raise ActiveRecord::ReadOnlyRecord, "financial ledger entries are immutable" }
  end
end
