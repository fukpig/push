class ChangePlainIdToDomainInBillingSubscription < ActiveRecord::Migration
  def change
   rename_column :billing_subscriptions, :plan_id, :domain
   change_column :billing_subscriptions, :domain, :string
  end
end
