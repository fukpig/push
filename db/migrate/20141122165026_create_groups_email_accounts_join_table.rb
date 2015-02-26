class CreateGroupsEmailAccountsJoinTable < ActiveRecord::Migration
  def change
    create_join_table :groups, :email_accounts do |t|
      # t.index [:group_id, :email_account_id]
      # t.index [:email_account_id, :group_id]
    end
  end
end
