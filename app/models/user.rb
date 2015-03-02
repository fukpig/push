class User < ActiveRecord::Base
  has_paper_trail 
  has_many :api_keys, dependent: :destroy
  has_many :domains, dependent: :destroy
  has_many :email_accounts
  has_many :companies, dependent: :destroy
  has_one :user_role

  has_many :billing_subscriptions, :class_name => 'Billing::Subscription'

  has_many :billing_subscription,
    :class_name => 'Billing::Subscription',
    #:conditions => proc {
      #["billing_subscriptions.subscription_date <= ? AND (billing_subscriptions.unsubscription_date IS NULL OR billing_subscriptions.unsubscription_date > ?)", Date.today, Date.today]
    #},
    :dependent => :destroy,
    :inverse_of => :user


  has_many :billing_invoices, :class_name => 'Billing::Invoice', :dependent => :destroy, :inverse_of => :user
  has_many :billing_transactions, :class_name => 'Billing::Transaction', :dependent => :destroy, :inverse_of => :user


  validates :cellphone, presence: true, uniqueness: true, length: { in: 6..40 },  format: { with: /\A[0-9]+\z/,
    message: "only allows numbers" }

  attr_accessor :locked_credit

  
  def self.get_belongs(roles)
    data = Array.new
	roles.each do |role|
      domain = Domain.where('id = ?', role.domain_id).first
      if domain
        email =  EmailAccount.where('user_id =? and domain_id = ?', current_user["id"], domain.id).first
        data << {"email_id" => email["id"], "email_name" => email["email"], "domain_id" => domain["id"], "domain_name" => domain["domain"]}
      end
    end
  end
  
  def send_sms(hash)
  	self.update_attribute(:confirmation_hash, Digest::SHA1.hexdigest(hash))
    require '/home/api-ps/smsc_api'
	sms = SMSC.new()
	ret = sms.send_sms('+' + self.cellphone, 'Your confirmation code:' + hash, 0, 0, 0, 0, 'ps-app', "maxsms=3")
	if ret[1] == '1'
	  return true
	else
	  raise ApiError.new("Send sms failed", "SEND_SMS_FAILED", "send sms failed")
	end
   end
   
   def check_code(code)
	 if !code.empty? && self.confirmation_hash == Digest::SHA1.hexdigest(code)
		return true 
	 else 
		 raise ApiError.new("Confirm user failed", "USER_CONFIRM_FAILED", "not valid code")
	 end
   end
   
   def activate
    if self.aasm_state == 'recover' 
      recovery_user = User.where('cellphone = ?', self.recovery_cellphone).first
      user.update_attribute(:internal_credit, recovery_user.internal_credit)
      Domain.where('recovery_cellphone = ?', self.recovery_cellphone).update_all(user_id: user.id)
    end
	  
    self.update_attribute( :activated, true ) 
    self.update_attributes(:aasm_state => 'active', :temp_device_token => '', :confirmation_hash => '')
	  api_key = self.find_api_key
   end
   
   def set_recovery_cellphone(recovery_cellphone)

	  if recovery_cellphone == self.cellphone 	
		  raise ApiError.new("Register domain failed", "REG_DOMAIN_FAILED", "recovery cellphone similar user main cellphone")
		end 
		
		if recovery_cellphone != self.recovery_cellphone && self.domains.count > 0
		  raise ApiError.new("Register domain failed", "REG_DOMAIN_FAILED", "recovery_cellphone doesnt match first recovery cellphone'") 
		else
		  self.recovery_cellphone = recovery_cellphone
		  self.save!
		end
	end
   
   
   
   
  
  def add_user_to_company(role, domain_id)
    UserToCompanyRole.create(user_id: self.id, role_id:2, domain_id: domain_id)
  end


  def pay_domain(domain_id)
    domain = Domain.find(domain_id)
    type_of = 'create_domain'
    domain_zone = domain['domain'].split(".")[1]
    zone = PsConfigZones.where("name = ?", domain_zone).first
    full_amount = zone.ps_price
    invoice = create_invoice(self, domain, full_amount, type_of)
    pay!(invoice)
  end

  def pay_email(domain_id, interval)
    domain = Domain.find(domain_id)
    type_of = 'create_email'
    full_amount = EmailAccount.amount_per_day + (interval-1)*5
    invoice = create_invoice(self, domain, full_amount, type_of)
    pay!(invoice)
  end

  def invoice!(type_of, domain_id)
    domain = Domain.find(domain_id)
    full_amount = get_full_amount(type_of, domain)
    invoice = create_invoice(self, domain, full_amount, type_of)
    pay!(invoice)
  end  

  def get_full_amount(type_of, domain)
    if type_of == 'domain'
      full_amount = 7
    elseif type_of == 'email_create'
      full_amount = EmailAccount.amount_per_day
    else
      full_amount = 5*domain.email_accounts.count
    end
    return full_amount
  end

  def create_invoice(user, domain, full_amount, type)
    check_balance(full_amount)      
    invoice = self.billing_invoices.create! do |i|
      i.user = user
      i.type_of = type
      i.domain_id = domain.id
      i.params = domain.domain     
      i.full_amount = full_amount
      i.title = domain.domain
      i.credit_deduction = 0     
      i.amount = 0
    end
    return invoice
  end
  
  def create_subscriptions(domain_id)
    self.billing_subscription.create(type_of: 'domain', domain: domain_id, billed_at: Date.today)
    self.billing_subscription.create(type_of: 'email', domain: domain_id)
  end

  def pay!(invoice)
    invoice.amount = self.from_credit(invoice.full_amount, invoice.id)
    invoice.paid_at = Time.now
    invoice.save
  end

  def check_balance(amount)
    balance = self.internal_credit-amount
    raise ApiError.new("Payment failed", "PAY_FAILED", "Not enough credit") unless balance > 0
  end

  def find_api_key ()
    self.api_keys.first_or_create
  end

  def to_credit(amount)           
    success = transaction do
      self.lock_internal_credit!
      self.internal_credit += amount.abs      
      self.save(:validate => false)            
    end
    amount = (self.internal_credit - self.locked_credit).abs
    
    self.billing_transactions.create(
      :action => 'internal_credit_replenishment',
      :amount => amount,
      :success => success    
    ) if amount != 0       
    
    return amount
  end

  def from_credit(amount, invoice_id)        
    success = transaction do
      self.lock_internal_credit!
      self.internal_credit < amount.abs ? self.internal_credit = 0 : self.internal_credit -= amount.abs        
      self.save(:validate => false)
    end
    amount = (self.locked_credit - self.internal_credit).abs
    
    self.billing_transactions.create(
      :action => 'internal_credit_withdrawal',
      :invoice_id => invoice_id,
      :amount => amount,
      :success => success    
    ) if amount != 0       
    
    return amount
  end

  def enough_credit?(full_amount)
    raise ApiError.new("Payment failed", "PAY_FAILED", "Not enough credit") unless self.internal_credit >= full_amount
  end  

  protected

  def lock_internal_credit!
    self.lock!
    self.locked_credit = self.internal_credit
  end

end
