class Domain < ActiveRecord::Base
    belongs_to :user
    has_many :groups, dependent: :destroy
    has_many :email_accounts, dependent: :destroy

    validates :domain, presence: true, uniqueness: true
	
	
	def self.list(user)
		domains = user.domains
		domains_info = Array.new()
		domains.each do |domain|
		  next_billing_date = get_next_billing_date(domain)
		  domains_info << {"id" => domain.id, "domain" => domain.domain, "registration_date"=>domain.registration_date, "expiry_date"=>domain.expiry_date, "status"=>domain.status, "next_billing_date"=>next_billing_date}
		end
	end
	
	def self.get_price(domain)
	  info = parse_domain(domain)
      zone = PsConfigZones.get_zone(info["domain_zone"])
	  result = Domain.whois(domain)  
      if result.available? == true
       {"domain_price" => zone.ps_price, "email_price" => EmailAccount.amount_per_day}
      end
	end
	
	def self.get_variants(domain)
		info = parse_domain(domain)
		reg_ru = RegApi2.domain.get_suggest(word: info["domain_word"],
        use_hyphen: "1",
		  category: "pattern",
		  limit: "5",
		  tlds: ["su", "ru", "com"],
		)
		variants = Array.new
		i = 0
		reg_ru.each do |variant|
		  break if i == 4
		  variant["avail_in"].each do |zone|
			i += 1
			break if i == 4
			variants << variant["name"] + "." + zone
		  end
		  
		end
		return variants
	end
	
	
	def self.parse_domain(domain)
	   info = domain.split(".")
	   {"domain_word" => info.first, "domain_zone" =>info.second}
	end
	
	
	def self.get_invite_domains(current_user, model)
	    list = Array.new
		if model == 'domains'
		  rows = DelegatedDomain.where(["to = ?", current_user.id])
		else 
		  rows = Invite.where(["cellphone = ?", current_user.cellphone])
		end
		rows.each do |row|
		  list << Domain.add_to_list(domain) unless row.accepted?
		end
	end
	
	def self.add_to_list(info)
		info = Hash.new
		domain = Domain.where(["id = ?", info["domain_id"]]).first
		inviter = User.where(["id = ?", domain["inviter_id"]]).first
		info = { "id" => domain["id"], "domain_id" => domain["domain_id"], "domain"=> domain["domain"], "inviter_id" => domain["inviter_id"], "inviter_name" => domain["name"]}
	end
	
	def self.check_domain(domain)
	  raise ApiError.new("find domain failed", "FIND_DOMAIN_FAILED", "domain not found") if domain.nil?
	end
	
	def self.register(current_user, info)
		result = Domain.whois(info["domain"])
	
		if result.available?
			zone = PsConfigZones.get_zone(info["zone"])
		
			current_user.check_balance(zone.ps_price + EmailAccount.amount_per_day)
			Domain.transaction do
				domain = Domain.create(user_id: current_user.id, domain: info["domain"], registration_date: DateTime.now, expiry_date: 1.year.from_now, status: 'ok')
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
				  EmailAccount.create_email(current_user, domain.id, info["email_name"], 'admin', '')
		
				  current_user.pay_domain(domain.id)
		
		interval = 1
		current_user.pay_email(domain.id, interval)
		
		current_user.create_subscriptions(domain.id)
		
		#SET ADMIN TO DOMAIN
		current_user.add_user_to_company(1, domain.id)
   	    return domain




				  return domain
				else
				  raise ApiError.new("Register domain failed", "REG_DOMAIN_FAILED", domain.errors)
				end
		end
	else 
		raise ApiError.new("Register domain failed", "REG_DOMAIN_FAILED", 'Domain is not available')
	end
	
	
	
		
    end
	
	def self.get_next_billing_date(domain)
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
