class CreateBillingPlans < ActiveRecord::Migration
  def change
    create_table :billing_plans do |t|
      t.string :title
      t.string :key
      t.decimal :monthly_amount, :precision => 8, :scale => 2
      t.decimal :annual_amount, :precision => 8, :scale => 2

      t.timestamps
    end
  end
end
