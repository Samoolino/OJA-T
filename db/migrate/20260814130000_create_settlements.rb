class CreateSettlements < ActiveRecord::Migration[7.0]
  def change
    create_table :settlements do |t|
      t.references :order, null: false, foreign_key: { to_table: :spree_orders }
      t.string :vendor_reference, null: false
      t.bigint :gross_amount, null: false
      t.bigint :platform_fee, null: false, default: 0
      t.bigint :net_amount, null: false
      t.string :currency, null: false
      t.string :status, null: false, default: "pending"
      t.string :settlement_strategy, null: false, default: "delayed"
      t.string :settlement_reference, null: false
      t.string :provider
      t.string :provider_reference
      t.datetime :eligible_at
      t.datetime :settled_at
      t.timestamps
    end

    add_index :settlements, :settlement_reference, unique: true
    add_index :settlements, [:order_id, :vendor_reference], unique: true
    add_index :settlements, [:provider, :provider_reference], unique: true, where: "provider_reference IS NOT NULL"
    add_check_constraint :settlements, "gross_amount >= 0", name: "settlements_gross_amount_non_negative"
    add_check_constraint :settlements, "platform_fee >= 0", name: "settlements_platform_fee_non_negative"
    add_check_constraint :settlements, "net_amount >= 0", name: "settlements_net_amount_non_negative"
  end
end
