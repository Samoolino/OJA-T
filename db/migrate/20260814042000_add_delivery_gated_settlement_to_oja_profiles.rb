class AddDeliveryGatedSettlementToOjaProfiles < ActiveRecord::Migration[7.2]
  def change
    add_column :oja_vendor_settlement_profiles, :settlement_requires_delivery_confirmation, :boolean, null: false, default: false
    add_index :oja_vendor_settlement_profiles, :settlement_requires_delivery_confirmation, name: "idx_oja_settlement_profiles_delivery_gate"
  end
end
