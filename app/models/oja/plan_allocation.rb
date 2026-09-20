module Oja
  class PlanAllocation < ActiveRecord::Base
    self.table_name = "oja_plan_allocations"

    belongs_to :plan, class_name: "Oja::Plan", inverse_of: :allocations
    has_many :ledger_entries, class_name: "Oja::FinancialLedgerEntry", foreign_key: :allocation_id, inverse_of: :allocation

    validates :beneficiary_id, :currency, presence: true
    validates :funded_minor, :reserved_minor, :consumed_minor, :released_minor, :reversed_minor,
              numericality: { greater_than_or_equal_to: 0 }

    def available_minor
      Oja::Financial::Invariants.available(
        funded_minor:, reserved_minor:, consumed_minor:, released_minor:, reversed_minor:
      )
    end
  end
end
