class CreateOjaFulfillmentAndSettlementRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :oja_order_fulfillments do |t|
      t.bigint :order_id, null: false
      t.string :vendor_reference, null: false
      t.string :fulfillment_mode, null: false
      t.string :status, null: false, default: "pending"
      t.string :tracking_reference
      t.string :idempotency_key, null: false
      t.string :correlation_id
      t.jsonb :metadata, null: false, default: {}
      t.datetime :confirmed_at
      t.timestamps
    end
    add_index :oja_order_fulfillments, :idempotency_key, unique: true
    add_index :oja_order_fulfillments, [:order_id, :vendor_reference]

    create_table :oja_settlement_records do |t|
      t.bigint :order_id, null: false
      t.string :vendor_reference, null: false
      t.bigint :allocation_id
      t.string :currency, null: false, limit: 3
      t.bigint :gross_amount_minor, null: false
      t.bigint :platform_fee_minor, null: false, default: 0
      t.bigint :net_amount_minor, null: false
      t.string :status, null: false, default: "created"
      t.string :correlation_id, null: false
      t.string :idempotency_key, null: false
      t.string :provider_reference
      t.string :connected_account_id
      t.jsonb :metadata, null: false, default: {}
      t.datetime :settled_at
      t.timestamps
    end
    add_index :oja_settlement_records, :idempotency_key, unique: true
    add_index :oja_settlement_records, [:order_id, :vendor_reference]
    add_check_constraint :oja_settlement_records, "gross_amount_minor >= 0 AND platform_fee_minor >= 0 AND net_amount_minor >= 0", name: "oja_settlement_amounts_nonnegative"
  end
end
