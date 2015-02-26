class CreateInvites < ActiveRecord::Migration
  def change
    create_table :invites do |t|
      t.string :cellphone
      t.integer :inviter_id
      t.integer :company_id
      t.boolean :accepted, :default => false

      t.timestamps
    end
  end
end
