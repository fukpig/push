class CreateBillingTransactions < ActiveRecord::Migration
  def change
    create_table :billing_transactions do |t|
      t.integer :user_id
      t.integer :invoice_id
      t.string :action
      t.decimal :amount, :precision => 8, :scale => 2
      t.boolean :success
      t.string :message
      t.text :params
      t.boolean :refunded

      t.timestamps
    end
  end
end
