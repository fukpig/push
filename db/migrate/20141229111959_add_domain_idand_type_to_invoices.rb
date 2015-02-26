class AddDomainIdandTypeToInvoices < ActiveRecord::Migration
  def change
     add_column :billing_invoices, :domain_id, :integer
     add_column :billing_invoices, :type_of, :string
  end
end
