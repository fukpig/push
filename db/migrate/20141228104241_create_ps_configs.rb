class CreatePsConfigs < ActiveRecord::Migration
  def change
    create_table :ps_configs do |t|
      t.string :name
      t.string :value

      t.timestamps
    end
  end
end
