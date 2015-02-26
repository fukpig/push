class Invite < ActiveRecord::Base

	validates :cellphone, presence: true, length: { in: 6..40 },  format: { with: /\A[0-9]+\z/,
    message: "only allows numbers" }
  validates :inviter_id, presence: true
  validates :domain_id, presence: true
  validates :name, presence: true
  validates :email_id, presence: true

	def self.create_invite(data)
	  user = User.find(data['user_id'])
	  check_existed_user(data['cellphone'], data['domain_id'], data['email_id'])
  	  check_invite_himself(user['cellphone'], data['cellphone'])
  	  #CHECK_EMAIL
  	  domain_owner?(user.domains, data['domain_id'])
	  invite = Invite.create(cellphone:  data['cellphone'], inviter_id: user['id'], domain_id: data['domain_id'], name: data['name'], email_id: data['email_id'])
	  if (!User.where(["cellphone = ?", data['cellphone']]).present?)
	    return save_invite(invite)
	  else 
	    return {"isset"=>"false", "message"=>"invite has been added"}
	  end
	end

	def self.check_existed_user(cellphone, domain_id, email_id)
  	  invite = Invite.where(["cellphone = ? and domain_id = ? and email_id = ?", cellphone, domain_id, email_id]).first
  	  raise ApiError.new("Send invite failed", "SEND_INVITE_FAILED", "invite already sended") unless !invite
    end

    def self.check_invite_himself(user_cellphone, cellphone)
  	  raise ApiError.new("Send invite failed", "SEND_INVITE_FAILED", "invalid cellphone") unless cellphone != user_cellphone
    end

    def self.save_invite(invite)
  	  if !invite.new_record?
	    return {"isset"=>"true", "message"=>"invite has been added"}
	  else
	  	raise ApiError.new("Create invite failed", "CREATE_INVITE_FAILED", invite.errors)
	  end
    end

    def self.domain_owner?(domains, domain_id) 
	  if domains.where(["id = ?", domain_id]).present?
	    return true
	  else
	    raise ApiError.new("Domain not found", "FIND_DOMAIN_FAILED", "domain not found")
	  end
	end
end
