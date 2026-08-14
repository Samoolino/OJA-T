class FixOjaOrderAllocationOrderReference < ActiveRecord::Migration[7.2]
  def up
    return unless table_exists?(:oja_order_allocations)

    change_column :oja_order_allocations, :order_id, :bigint, using: "order_id::bigint", null: false

    add_foreign_key :oja_order_allocations, :spree_orders, column: :order_id unless foreign_key_exists?(:oja_order_allocations, :spree_orders, column: :order_id)
  end

  def down
    remove_foreign_key :oja_order_allocations, :spree_orders if foreign_key_exists?(:oja_order_allocations, :spree_orders, column: :order_id)
    change_column :oja_order_allocations, :order_id, :string, using: "order_id::text", null: false
  end
end
