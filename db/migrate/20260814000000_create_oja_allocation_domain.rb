class CreateOjaAllocationDomain < ActiveRecord::Migration[7.2]
  def change
    create_table :oja_plan_owners do |t|
      t.string :name, null: false
      t.string :status, null: false, default: "active"
      t.string :external_reference
      t.timestamps
    end

    create_table :oja_plans do |t|
      t.references :plan_owner, null: false, foreign_key: { to_table: :oja_plan_owners }
      t.string :name, null: false
      t.text :description
      t.string :currency, null: false, limit: 3
      t.decimal :funding_target, precision: 20, scale: 2, null: false, default: 0
      t.string :allocation_mode, null: false, default: "manual"
      t.string :spending_mode, null: false, default: "multi_allocation"
      t.string :status, null: false, default: "draft"
      t.datetime :starts_at
      t.datetime :ends_at
      t.timestamps
    end

    create_table :oja_plan_subscriptions do |t|
      t.references :plan, null: false, foreign_key: { to_table: :oja_plans }
      t.string :interval, null: false
      t.decimal :amount, precision: 20, scale: 2, null: false
      t.string :currency, null: false, limit: 3
      t.datetime :next_billing_at
      t.string :status, null: false, default: "active"
      t.string :external_subscription_reference
      t.timestamps
    end

    create_table :oja_plan_fundings do |t|
      t.references :plan, null: false, foreign_key: { to_table: :oja_plans }
      t.decimal :amount, precision: 20, scale: 2, null: false
      t.string :currency, null: false, limit: 3
      t.string :external_payment_reference
      t.string :status, null: false, default: "pending"
      t.datetime :funded_at
      t.timestamps
    end

    create_table :oja_receivers do |t|
      t.string :external_reference
      t.string :status, null: false, default: "active"
      t.timestamps
    end

    create_table :oja_plan_allocations do |t|
      t.references :plan, null: false, foreign_key: { to_table: :oja_plans }
      t.references :receiver, null: false, foreign_key: { to_table: :oja_receivers }
      t.decimal :original_amount, precision: 20, scale: 2, null: false
      t.decimal :consumed_amount, precision: 20, scale: 2, null: false, default: 0
      t.decimal :reserved_amount, precision: 20, scale: 2, null: false, default: 0
      t.string :currency, null: false, limit: 3
      t.string :allocation_reference, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :starts_at
      t.datetime :expires_at
      t.timestamps
    end
    add_index :oja_plan_allocations, :allocation_reference, unique: true

    create_table :oja_allocation_ledger_entries do |t|
      t.references :allocation, null: false, foreign_key: { to_table: :oja_plan_allocations }
      t.string :entry_type, null: false
      t.decimal :amount, precision: 20, scale: 2, null: false
      t.string :currency, null: false, limit: 3
      t.string :reference_type
      t.string :reference_id
      t.string :idempotency_key, null: false
      t.decimal :balance_snapshot, precision: 20, scale: 2
      t.timestamps
    end
    add_index :oja_allocation_ledger_entries, :idempotency_key, unique: true

    create_table :oja_allocation_reservations do |t|
      t.references :allocation, null: false, foreign_key: { to_table: :oja_plan_allocations }
      t.bigint :order_id
      t.decimal :amount, precision: 20, scale: 2, null: false
      t.string :currency, null: false, limit: 3
      t.string :status, null: false, default: "active"
      t.datetime :expires_at, null: false
      t.string :idempotency_key, null: false
      t.datetime :released_at
      t.datetime :consumed_at
      t.timestamps
    end
    add_index :oja_allocation_reservations, :idempotency_key, unique: true
    add_index :oja_allocation_reservations, :order_id
  end
end
