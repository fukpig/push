class Billing::Subscription < ActiveRecord::Base
  self.table_name = 'billing_subscriptions'

  belongs_to :user, :inverse_of => :billing_subscription
 
  before_validation :set_billing_dates, :on => :create
  
  validates :user, :presence => true  

  validates :subscription_date, :presence => true
  
  validates :next_billing_date, :presence => true
  
  default_value_for :subscription_date do 
    Date.today
  end
  
  #default_scope order(:subscription_date.desc)
  
  scope :active, ->{where("billing_subscriptions.subscription_date <= ? AND (billing_subscriptions.unsubscription_date IS NULL OR billing_subscriptions.unsubscription_date > ?)", Date.today, Date.today)}
  scope :should_be_billed, ->{where("( billing_subscriptions.next_billing_date <= ? ) AND (billing_subscriptions.unsubscription_date IS NULL)", Date.today)}

 
  attr_readonly :user
        
  def previous_action_date
    self.previous_billing_date || self.subscription_date
  end
  
  def days
    (self.next_billing_date - self.previous_action_date).to_i
  end
  
  def days_spent
    (Date.today - self.previous_action_date).to_i
  end
  
  def days_unspent
    (self.next_billing_date - Date.today).to_i
  end    

  def next_month
    Date.today.at_beginning_of_month.next_month
  end

  def bill_async
    Delayed::Job.enqueue(SubscriptionBillJob.new(self.id))
  end
  
  def bill(options={})    
    #if (self.next_billing_date <= Date.today) && (self.unsubscription_date.nil? || self.unsubscription_date > Date.today)         
      self.class.transaction do        
        self.set_billing_dates

        title = 'Test'
        self.user.invoice!(self.type_of, self.domain)
        
        self.billed_at = Time.now
        self.save!
      end
  end
  
  def cancel(date = Date.today, options = {})
    options.reverse_merge!({
      :refund => false
    })
    
    date = Date.today if date < Date.today
    transaction do
      self.user.to_credit(self.amount_unspent) if options[:refund]
      self.unsubscription_date = date      
      # self.additional_services.not_unsubscribed_at(Date.today).each{ |s| s.cancel!(:date => date, :validate => false) }
      self.save
    end    
  end    
  
  delegate :amount, :amount_params, :amount_spent, :amount_spent_params, :to => :calculator

  def inherit(user)    
    current_subscription = user.billing_subscription

    return if current_subscription.blank?

    # self.next_billing_date = current_subscription.next_billing_date if subscription.trial?
    
    # self.inherit_additional_services!(subscription)
  end

protected
  
  def set_billing_dates
    #if !self.new_record?
      #self.previous_billing_date = self.next_billing_date
    #end
    #if self.type_of == 'domain'
      #self.next_billing_date = self.previous_billing_date+1.year
    #else
      #self.next_billing_date = next_month
    #end  
    if self.new_record?      
      # set next billing date only if it is not predefined
      if self.next_billing_date.nil?
        self.next_billing_date = self.get_dates(self.type_of)
      end
    else
      self.previous_billing_date = self.next_billing_date
      self.next_billing_date = self.get_dates(self.type_of)
    end
  end

  def get_dates(type)
    if type == 'domain'
      if self.previous_billing_date.nil?
        self.previous_billing_date = Date.today
      end
      return self.previous_billing_date+1.year
    else
      return self.next_month
    end
  end
end