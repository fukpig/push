class AddTitleToBillingInvoices < ActiveRecord::Migration
  def change
    add_column :billing_invoices, :title, :string
    add_column :billing_invoices, :credit_deduction, :decimal , :precision => 8, :scale => 2
  end
end
