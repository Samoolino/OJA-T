class AddProviderFieldsToSettlements < ActiveRecord::Migration[7.2]
  def change
    add_column :settlements, :provider, :string unless column_exists?(:settlements, :provider)
    add_column :settlements, :provider_reference, :string unless column_exists?(:settlements, :provider_reference)

    add_index :settlements, :provider_reference, unique: true, where: "provider_reference IS NOT NULL", name: "index_settlements_on_provider_reference" unless index_exists?(:settlements, :provider_reference, name: "index_settlements_on_provider_reference")
  end
end
