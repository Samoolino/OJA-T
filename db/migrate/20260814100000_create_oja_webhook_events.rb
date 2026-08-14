class CreateOjaWebhookEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :oja_webhook_events do |t|
      t.string :event_id, null: false
      t.string :provider, null: false
      t.string :event_type, null: false
      t.string :external_reference, null: false
      t.jsonb :payload, null: false, default: {}
      t.datetime :processed_at
      t.timestamps
    end

    add_index :oja_webhook_events, :event_id, unique: true
    add_index :oja_webhook_events, [:provider, :external_reference]
  end
end
