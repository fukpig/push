class CreateDomain < ActiveRecord::Migration
  def change
    create_table :domains do |t|
      t.integer :user_id
      t.date :registration_date
      t.string :domain
      t.date :expiry_date
      t.string :status
    end
  end
end
