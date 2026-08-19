class AddVendorSettlementContextToOjaOrderAllocations < ActiveRecord::Migration[7.2]
  def change
    add_reference :oja_order_allocations,
                  :settlement_profile,
                  null: false,
                  foreign_key: { to_table: :oja_vendor_settlement_profiles }
    add_column :oja_order_allocations, :vendor_reference, :string, null: false
    add_index :oja_order_allocations, :vendor_reference
  end
end
