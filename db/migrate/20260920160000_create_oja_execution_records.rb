class CreateOjaExecutionRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :oja_plans do |t|
      t.bigint :plan_owner_id, null: false
      t.string :name, null: false
      t.string :currency, null: false, limit: 3
      t.bigint :funding_target_minor, null: false, default: 0
      t.string :status, null: false, default: "draft"
      t.datetime :starts_at
      t.datetime :ends_at
      t.timestamps
    end
    add_index :oja_plans, :plan_owner_id
    add_check_constraint :oja_plans, "funding_target_minor >= 0", name: "oja_plans_funding_target_nonnegative"

    create_table :oja_plan_allocations do |t|
      t.bigint :plan_id, null: false
      t.string :beneficiary_id, null: false
      t.string :currency, null: false, limit: 3
      t.bigint :funded_minor, null: false, default: 0
      t.bigint :reserved_minor, null: false, default: 0
      t.bigint :consumed_minor, null: false, default: 0
      t.bigint :released_minor, null: false, default: 0
      t.bigint :reversed_minor, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.datetime :expires_at
      t.jsonb :geo_policy, null: false, default: {}
      t.timestamps
    end
    add_index :oja_plan_allocations, [:plan_id, :beneficiary_id]
    add_check_constraint :oja_plan_allocations, "funded_minor >= 0 AND reserved_minor >= 0 AND consumed_minor >= 0 AND released_minor >= 0 AND reversed_minor >= 0", name: "oja_allocations_counters_nonnegative"

    create_table :oja_financial_ledger_entries do |t|
      t.bigint :allocation_id, null: false
      t.string :operation_id, null: false
      t.string :idempotency_key, null: false
      t.string :entry_type, null: false
      t.bigint :amount_minor, null: false
      t.string :currency, null: false, limit: 3
      t.string :correlation_id, null: false
      t.string :source_type
      t.string :source_id
      t.jsonb :metadata, null: false, default: {}
      t.datetime :effective_at, null: false
      t.timestamps
    end
    add_index :oja_financial_ledger_entries, :operation_id, unique: true
    add_index :oja_financial_ledger_entries, [:allocation_id, :idempotency_key], unique: true, name: "idx_oja_ledger_allocation_idempotency"
    add_check_constraint :oja_financial_ledger_entries, "amount_minor > 0", name: "oja_ledger_amount_positive"

    create_table :oja_payment_evidence_events do |t|
      t.string :provider, null: false
      t.string :provider_event_id, null: false
      t.string :event_type, null: false
      t.string :payment_reference
      t.string :order_reference
      t.string :currency, limit: 3
      t.bigint :amount_minor
      t.string :correlation_id
      t.string :payload_fingerprint, limit: 64
      t.jsonb :payload, null: false, default: {}
      t.datetime :occurred_at
      t.timestamps
    end
    add_index :oja_payment_evidence_events, [:provider, :provider_event_id], unique: true, name: "idx_oja_payment_evidence_provider_event"
    add_index :oja_payment_evidence_events, :payload_fingerprint
    add_check_constraint :oja_payment_evidence_events, "amount_minor IS NULL OR amount_minor >= 0", name: "oja_payment_evidence_amount_nonnegative"

    create_table :oja_reconciliation_records do |t|
      t.string :provider, null: false
      t.string :provider_event_id, null: false
      t.string :payment_reference
      t.string :order_reference
      t.string :status, null: false, default: "UNMATCHED"
      t.string :expected_currency, limit: 3
      t.bigint :expected_amount_minor
      t.string :observed_currency, limit: 3
      t.bigint :observed_amount_minor
      t.string :correlation_id
      t.string :resolution_operation_id
      t.jsonb :metadata, null: false, default: {}
      t.datetime :resolved_at
      t.timestamps
    end
    add_index :oja_reconciliation_records, [:provider, :provider_event_id], unique: true, name: "idx_oja_reconciliation_provider_event"
    add_check_constraint :oja_reconciliation_records, "expected_amount_minor IS NULL OR expected_amount_minor >= 0", name: "oja_reconciliation_expected_nonnegative"
    add_check_constraint :oja_reconciliation_records, "observed_amount_minor IS NULL OR observed_amount_minor >= 0", name: "oja_reconciliation_observed_nonnegative"
  end
end
