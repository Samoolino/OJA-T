class CreateOjaOrderSplits < ActiveRecord::Migration[7.0]
  def change
    create_table :oja_order_splits do |t|
      t.string :order_reference, null: false
      t.string :cart_reference, null: false
      t.bigint :vendor_id, null: false
      t.bigint :vendor_store_id, null: false
      t.string :currency, null: false, limit: 3
      t.bigint :amount_minor, null: false
      t.string :status, null: false, default: "CREATED"
      t.string :payment_reference
      t.string :fulfillment_status, null: false, default: "PENDING"
      t.string :transfer_idempotency_key
      t.string :correlation_id, null: false
      t.jsonb :line_items, null: false, default: []
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :oja_order_splits, [:order_reference, :vendor_id, :vendor_store_id], unique: true, name: "idx_oja_order_splits_order_vendor_store"
    add_index :oja_order_splits, :cart_reference
    add_index :oja_order_splits, :payment_reference
    add_check_constraint :oja_order_splits, "amount_minor >= 0 AND vendor_id > 0 AND vendor_store_id > 0", name: "oja_order_splits_amount_and_identity_positive"
  end
end
