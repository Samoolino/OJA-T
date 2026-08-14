class AddTransactionLineageToOjaPaymentIntents < ActiveRecord::Migration[7.2]
  def change
    change_table :oja_payment_intents, bulk: true do |t|
      t.string :idempotency_key
      t.datetime :authorized_at
      t.datetime :completed_at
    end

    add_index :oja_payment_intents, :order_id, unique: true
    add_index :oja_payment_intents, :idempotency_key, unique: true
    add_foreign_key :oja_payment_intents, :spree_orders, column: :order_id
  end
end
