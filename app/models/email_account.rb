class EmailAccount < ActiveRecord::Base
    require 'yandex'


    belongs_to :user
    belongs_to :company
    belongs_to :domain
    has_and_belongs_to_many :groups

    validates :user_id, presence: true
    validates :domain_id, presence: true
    validates :email, :presence => true, uniqueness: true, format: { with: /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/,
    message: "not valid email" }

    scope :common, ->{ where('is_admin = ?', 'f') }

    def self.create_email(current_user, domain_id, email, role, name)
       	domain = current_user.domains.where(["id = ?", domain_id]).first
       	email_name = "#{email}@#{domain['domain']}".downcase
       	#TODO DELETE THIS SHIT
       	email = EmailAccount.create(user_id: current_user['id'], domain_id: domain['id'], email: email_name, is_admin: self.get_role(role), name: name, is_enabled: true)

       	if !email.new_record?
          #YANDEX
          #YANDEX
       	  return email
        else
          raise ApiError.new("Register email failed", "REG_EMAIL_FAILED", "email already exist")
       	end
    end
	
	def self.list(domain_ids)
	  emails = EmailAccount.where("domain_id IN (?)", domain_ids)
	  data = Array.new
	  emails.each do |email|
	    name = email["name"]
	    name = email.user["name"] if email.is_admin?	
		status = "no"
		status = "yes" if email.is_enabled?
		
		data << {"id" => email["id"],"email" => email["email"],"name" => name, "cellphone" => email.user["cellphone"], "enabled" => status}
	  end
	end
	

    def self.get_role(role)
    	if role == 'admin'
    		return true
    	else 
    		return false
    	end
    end

    def self.amount_per_day
    	days = (Date.today.at_beginning_of_month.next_month - Date.today).to_i
    	days*((5.to_f / 30).round(2))
    end

    def self.split_email(email)
        array = email.split("@")
		raise ApiError.new("Check email failed", "CHECK_EMAIL_FAILED", "Email not valid") if array.count < 2
        if array[0].match('[a-zA-Z0-9\.\-\s]+')
          return {"email_name" => array[0], "domain" => array[1], "zone" => array[1].split(".")[1]}
        else
          raise ApiError.new("Check email failed", "CHECK_EMAIL_FAILED", "Email not latin")
        end  
    end
	
	def self.change_owner(domain_id)
	   EmailAccount.where('domain_id = ?', domain_id).update_all(domain_id:domain_id)
	end
end
