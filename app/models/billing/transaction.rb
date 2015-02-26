class Billing::Transaction < ActiveRecord::Base
  self.table_name = 'billing_transactions'
  
  ACTIONS = ['braintree_payment', 'internal_credit_replenishment', 'internal_credit_withdrawal']

  belongs_to :user
  belongs_to :invoice, :class_name => "Billing::Invoice"
  serialize :params
    
  validates :amount,
    :presence => true,
    :numericality => {
      :greater_than_or_equal_to => 0
    }

  validates :user, :presence => true

  validates :action, :inclusion => { :in => ACTIONS }
  
  attr_readonly :user, :invoice, :action, :amount, :success
  
  scope :recent, lambda{ |count| order('created_at DESC').limit(count) }
end
