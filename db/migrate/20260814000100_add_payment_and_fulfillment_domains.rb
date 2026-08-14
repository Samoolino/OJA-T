class AddPaymentAndFulfillmentDomains < ActiveRecord::Migration[7.1]
  def change
    create_table :oja_payment_intents do |t|
      t.string :payment_intent_id, null: false
      t.bigint :order_id
      t.bigint :receiver_id
      t.string :vendor_reference
      t.decimal :amount, precision: 20, scale: 2, null: false
      t.string :currency, limit: 3, null: false
      t.string :funding_source, null: false
      t.string :authorization_method, null: false
      t.string :status, null: false, default: "pending"
      t.string :nonce, null: false
      t.text :challenge
      t.datetime :expires_at, null: false
      t.jsonb :allocation_ids, null: false, default: []
      t.string :delivery_method
      t.timestamps
    end

    add_index :oja_payment_intents, :payment_intent_id, unique: true
    add_index :oja_payment_intents, :nonce, unique: true
    add_index :oja_payment_intents, [:receiver_id, :status]

    create_table :oja_vendor_fulfillment_profiles do |t|
      t.string :vendor_reference, null: false
      t.string :fulfillment_mode, null: false, default: "courier"
      t.string :delivery_provider
      t.string :delivery_regions, array: true, default: []
      t.integer :processing_time_hours, null: false, default: 0
      t.integer :delivery_sla_hours, null: false, default: 0
      t.boolean :pickup_available, null: false, default: false
      t.boolean :tracking_supported, null: false, default: false
      t.boolean :proof_of_delivery_required, null: false, default: false
      t.timestamps
    end

    add_index :oja_vendor_fulfillment_profiles, :vendor_reference, unique: true
  end
end
