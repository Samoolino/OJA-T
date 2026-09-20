class AddOjaTransferAndFulfillmentIntegrity < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :oja_settlement_records, :oja_plan_allocations, column: :allocation_id
    add_index :oja_settlement_records, [:order_id, :vendor_reference], unique: true, name: "idx_oja_settlements_order_vendor_unique"
    add_index :oja_order_fulfillments, [:order_id, :vendor_reference], unique: true, name: "idx_oja_fulfillments_order_vendor_unique"
    add_check_constraint :oja_settlement_records,
                         "gross_amount_minor >= platform_fee_minor AND net_amount_minor = gross_amount_minor - platform_fee_minor",
                         name: "oja_settlement_net_amount_integrity"
    add_check_constraint :oja_settlement_records,
                         "allocation_id IS NULL OR allocation_id > 0",
                         name: "oja_settlement_allocation_positive"
  end
end
