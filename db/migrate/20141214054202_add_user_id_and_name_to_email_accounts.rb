class AddUserIdAndNameToEmailAccounts < ActiveRecord::Migration
  def change
    add_column :email_accounts, :name, :string
  end
end
