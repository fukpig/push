class AddIsAdminToEmailAccounts < ActiveRecord::Migration
  def change
    add_column :email_accounts, :is_admin, :boolean, :default => false
  end
end
