class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :cellphone
      t.string :name
      t.boolean :activated, :default => false
      t.string :confirmation_hash
      t.string :device_token
      t.string :recovery_cellphone
      t.string :recovery_hash
      t.string :aasm_state
      t.string :temp_device_token
    end
  end
end
