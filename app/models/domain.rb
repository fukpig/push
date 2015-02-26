class Domain < ActiveRecord::Base
    belongs_to :user
    has_many :groups, dependent: :destroy
    has_many :email_accounts, dependent: :destroy

    validates :domain, presence: true, uniqueness: true
	
	
	def list(user)
		domains = user.domains
		domains_info = Array.new()
		domains.each do |domain|
		  next_billing_date = get_next_billing_date(domain)
		  domains_info << {"id" => domain.id, "domain" => domain.domain, "registration_date"=>domain.registration_date, "expiry_date"=>domain.expiry_date, "status"=>domain.status, "next_billing_date"=>next_billing_date}
		end
	end
	
	
	def self.register(user_id, info)
		Domain.transaction do
			domain = Domain.create(user_id: user_id, domain: info["domain"], registration_date: DateTime.now, expiry_date: 1.year.from_now, status: 'ok')
			if !domain.new_record?			
			  #Yandex

			  #data = {:domain => info["domain"]}
			  #pdd = init_pdd
		  
			  #reg_domain_reg_ru(data)
			  
			  #result = pdd.domain_register(data[:domain])
			  #data[:cname] = 'yamail-'+ result["secrets"]["name"]
			  #set_records(data)

			  #cron = YandexCron.create(domain: info["domain"], email: info["email_name"])
			
			  #Yandex
			  return domain
			else
			  raise ApiError.new("Register domain failed", "REG_DOMAIN_FAILED", domain.errors)
			end
		end
    end
	
	def get_next_billing_date(domain)
		 subscription = Billing::Subscription.where('type_of = ? and domain = ?', 'domain', domain.domain).first
		  if subscription.nil?
			next_billing_date = nil 
		  else
			next_billing_date = subscription.next_billing_date
		  end
	end
	
	def self.whois(domain)
		begin
			Whois.whois(SimpleIDN.to_ascii(domain))
		rescue => e
			raise ApiError.new("Register domain failed", "REG_DOMAIN_FAILED", "invalid domain")  
		end
	end
	
	def self.change_owner(new_owner_id)
	  self.update_attribute( :user_id, new_owner_id.id ) 
	end
	
end
