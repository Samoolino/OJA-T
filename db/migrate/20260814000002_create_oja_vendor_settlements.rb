class CreateOjaVendorSettlements < ActiveRecord::Migration[7.2]
  def change
    create_table :oja_vendor_settlements do |t|
      t.references :order_allocation, null: false, foreign_key: { to_table: :oja_order_allocations }
      t.string :vendor_reference, null: false
      t.decimal :gross_amount, precision: 20, scale: 2, null: false
      t.decimal :platform_fee, precision: 20, scale: 2, null: false, default: 0
      t.decimal :net_amount, precision: 20, scale: 2, null: false
      t.string :currency, null: false, limit: 3
      t.string :status, null: false, default: "pending"
      t.string :external_settlement_reference
      t.datetime :settled_at
      t.timestamps
    end

    add_index :oja_vendor_settlements, :external_settlement_reference, unique: true, where: "external_settlement_reference IS NOT NULL", name: "idx_oja_vendor_settlements_external_ref"
  end
end
