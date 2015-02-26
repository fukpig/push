class CreateBillingSubscriptions < ActiveRecord::Migration
  def change
    create_table :billing_subscriptions do |t|
      t.string :type_of
      t.integer :user_id
      t.integer :plan_id
      t.date :subscription_date
      t.date :unsubscription_date
      t.timestamp :billed_at
      t.date :previous_billing_date
      t.date :next_billing_date

      t.timestamps
    end
  end
end
