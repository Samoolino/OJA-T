class AddOjaIntegrityConstraints < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :oja_plan_allocations, :oja_plans, column: :plan_id
    add_foreign_key :oja_financial_ledger_entries, :oja_plan_allocations, column: :allocation_id
    add_index :oja_plan_allocations, [:plan_id, :beneficiary_id], unique: true, name: "idx_oja_plan_beneficiary_unique"
  end
end
