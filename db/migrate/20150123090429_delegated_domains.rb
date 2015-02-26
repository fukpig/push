class DelegatedDomains < ActiveRecord::Migration
  def change
    create_table :delegated_domains do |t|
      t.integer :domain_id
      t.integer :from
      t.integer :to
      t.boolean :accepted, :default => false

      t.timestamps
    end

  end
end
