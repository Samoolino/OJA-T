class ExtendOjaVendorSettlementsForPayouts < ActiveRecord::Migration[7.2]
  def change
    add_column :oja_vendor_settlements, :payout_reference, :string
    add_column :oja_vendor_settlements, :destination_reference, :string
    add_index :oja_vendor_settlements, :payout_reference, unique: true
  end
end
