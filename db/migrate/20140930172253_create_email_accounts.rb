class CreateEmailAccounts < ActiveRecord::Migration
  def change
    create_table :email_accounts do |t|
      t.integer :provider_id
      t.string :email
      t.integer :company_id
      t.integer :user_id
      t.integer :domain_id

      t.timestamps
    end
  end
end
