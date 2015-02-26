class CreatePsConfigZones < ActiveRecord::Migration
  def change
    create_table :ps_config_zones do |t|
      t.string :name
      t.decimal :orig_price
      t.decimal :ps_price
      t.integer :years
    end
  end
end
