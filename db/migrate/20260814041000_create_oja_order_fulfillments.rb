class CreateOjaOrderFulfillments < ActiveRecord::Migration[7.2]
  def change
    create_table :oja_order_fulfillments do |t|
      t.bigint :order_id, null: false
      t.string :vendor_reference, null: false
      t.string :fulfillment_mode, null: false, default: "courier"
      t.string :status, null: false, default: "pending"
      t.string :idempotency_key, null: false
      t.string :tracking_reference
      t.datetime :shipped_at
      t.datetime :delivered_at
      t.datetime :delivery_confirmed_at
      t.timestamps
    end

    add_index :oja_order_fulfillments, [:order_id, :vendor_reference], unique: true, name: "idx_oja_fulfillments_order_vendor"
    add_index :oja_order_fulfillments, :idempotency_key, unique: true
    add_index :oja_order_fulfillments, :tracking_reference
    add_foreign_key :oja_order_fulfillments, :spree_orders, column: :order_id
  end
end
