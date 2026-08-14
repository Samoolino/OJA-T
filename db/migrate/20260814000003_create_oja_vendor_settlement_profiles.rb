class CreateOjaVendorSettlementProfiles < ActiveRecord::Migration[7.2]
  def change
    create_table :oja_vendor_settlement_profiles do |t|
      t.string :vendor_reference, null: false
      t.string :settlement_strategy, null: false, default: "instant"
      t.decimal :minimum_payout_threshold, precision: 20, scale: 2, null: false, default: 0
      t.bigint :settlement_delay_window, null: false, default: 0
      t.decimal :commission_rate, precision: 8, scale: 4, null: false, default: 5
      t.string :currency, null: false, limit: 3
      t.string :payout_destination_reference
      t.timestamps
    end

    add_index :oja_vendor_settlement_profiles, :vendor_reference, unique: true
    add_index :oja_vendor_settlement_profiles, :settlement_strategy
  end
end
