class CreateApiKeys < ActiveRecord::Migration
  def change
    create_table :api_keys do |t|
      t.integer :user_id
      t.string :access_token
      t.date :last_access
    end
  end
end
