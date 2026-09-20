module Oja
  class ReconciliationRecord < ActiveRecord::Base
    self.table_name = "oja_reconciliation_records"
    STATUSES = %w[MATCHED UNMATCHED MISSING DUPLICATE AMOUNT_MISMATCH CURRENCY_MISMATCH TIMING_DIFFERENCE].freeze
    validates :status, inclusion: { in: STATUSES }
    before_update { raise ActiveRecord::ReadOnlyRecord, "reconciliation records are immutable" }
    before_destroy { raise ActiveRecord::ReadOnlyRecord, "reconciliation records are immutable" }
  end
end
