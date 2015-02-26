class RemoveCompanyIdFromEmailaccounts < ActiveRecord::Migration
  def change
   remove_column :email_accounts, :company_id
  end
end
