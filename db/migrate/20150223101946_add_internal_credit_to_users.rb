class AddInternalCreditToUsers < ActiveRecord::Migration
  def change
    add_column :users, :internal_credit, :decimal
  end
end
