class ChangeCompanyIdToDomainIdInInvites < ActiveRecord::Migration
  def change
    rename_column :invites, :company_id, :domain_id
  end
end
