class CreateBillingInvoices < ActiveRecord::Migration
  def change
    create_table :billing_invoices do |t|
      t.integer :user_id
      t.decimal :full_amount, :precision => 8, :scale => 2
      t.decimal :amount, :precision => 8, :scale => 2
      t.text :params
      t.timestamp :paid_at
      t.date :issue_date
      t.date :due_date

      t.timestamps
    end
  end
end
