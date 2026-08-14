class CreateOjaOrderAllocations < ActiveRecord::Migration[7.2]
  def change
    create_table :oja_order_allocations do |t|
      t.references :allocation, null: false, foreign_key: { to_table: :oja_plan_allocations }
      t.references :reservation, null: false, foreign_key: { to_table: :oja_allocation_reservations }
      t.string :order_id, null: false
      t.decimal :amount, precision: 20, scale: 2, null: false
      t.string :currency, null: false, limit: 3
      t.timestamps
    end

    add_index :oja_order_allocations, [:order_id, :allocation_id], unique: true, name: "idx_oja_order_allocations_order_allocation"
  end
end
