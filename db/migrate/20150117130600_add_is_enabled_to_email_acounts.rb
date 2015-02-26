class AddIsEnabledToEmailAcounts < ActiveRecord::Migration
  def change
    add_column :email_accounts, :is_enabled, :boolean
  end
end
