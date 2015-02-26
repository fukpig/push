class CreateUserToCompanyRoles < ActiveRecord::Migration
  def change
    create_table :user_to_company_roles do |t|
      t.integer :user_id
      t.integer :role_id
      t.integer :domain_id

      t.timestamps
    end
  end
end
