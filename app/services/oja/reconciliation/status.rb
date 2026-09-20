module Oja
  module Reconciliation
    STATUSES = %w[MATCHED UNMATCHED MISSING DUPLICATE AMOUNT_MISMATCH CURRENCY_MISMATCH TIMING_DIFFERENCE].freeze
    module_function
    def blocking?(status)
      %w[UNMATCHED MISSING DUPLICATE AMOUNT_MISMATCH CURRENCY_MISMATCH].include?(status.to_s)
    end
  end
end
