class CreateOjaFundingIngresses < ActiveRecord::Migration[7.0]
  def change
    create_table :oja_funding_ingresses do |t|
      t.string :source_type, null: false
      t.string :source_reference, null: false
      t.string :provider, null: false
      t.string :status, null: false
      t.string :currency, null: false, limit: 3
      t.bigint :amount_minor, null: false
      t.string :idempotency_key, null: false
      t.string :correlation_id, null: false
      t.string :payload_fingerprint, limit: 64
      t.jsonb :evidence, null: false, default: {}
      t.datetime :occurred_at, null: false
      t.timestamps
    end
    add_index :oja_funding_ingresses, [:provider, :source_reference], unique: true
    add_index :oja_funding_ingresses, :idempotency_key, unique: true
    add_check_constraint :oja_funding_ingresses, "amount_minor > 0", name: "oja_funding_amount_positive"
  end
end
