class DelegatedDomain < ActiveRecord::Base

    validates :from, presence: true
    validates :to, presence: true

	def self.delegate(data)
	  check_existed_delegate(data['domain_id'], data['from'], data['to'])
  	  check_invite_himself(data['domain_id'], data['from'])
  	  #CHECK_EMAIL
  	  delegate = DelegatedDomain.create(domain_id:  data['domain_id'], from: data['from'], to: data['to'])
	  return {"message"=>"delegated domain has been added"}
	end

  def self.check_invite_himself(user_cellphone, cellphone)
  	raise ApiError.new("Send invite failed", "SEND_INVITE_FAILED", "invalid cellphone") unless cellphone != user_cellphone
  end

  def self.get_delegate_invite(user_id, invite_id)
	invite = DelegatedDomain.where(["to = ? and id=?",current_user.id, @params["delegate_id"]]).first
	if !invite.nil?
	  return invite
	else
	  raise ApiError.new("Accept invite failed", "ACCEPT_INVITE_FAILED", "no such invite")
	end
  end
	
	def self.accept
	 self.update_attribute( :accepted, true ) 
	end
end
