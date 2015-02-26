class AddNameAndEmailIdToInvite < ActiveRecord::Migration
  def change
    add_column :invites, :name, :string
    add_column :invites, :email_id, :integer
  end
end
