class Group < ActiveRecord::Base
	has_and_belongs_to_many :email_accounts

	validates :email, :presence => true, uniqueness: true
	
	def self.add_email(group, domain, email)
	  if email.nil? && email["domain_id"] != domain['id'].to_i
		info = { group_email => {"status"=>"errors", "message"=>"no such email"}}
		return info
	  end
      if !email.groups.where("email_account_id = ?", email["id"]).first
        group.email_accounts << email
        group.save!
        info = { group_email => {"status"=>"ok", "message"=>"email added to group"}}
      else
        info = { group_email => {"status"=>"errors", "message"=>"email already added to group"}}
      end
	  return info
	end
	
	def self.del_email(group, domain, email)
	  if email.nil? && email["domain_id"] != domain['id'].to_i
	    info = { group_email => {"status"=>"errors", "message"=>"no such email"}}
		return info
	  end
      in_group_email = group.email_accounts.find(email)
      if in_group_email
        group.email_accounts.delete(in_group_email)
        info = { group_email  => {"status"=>"ok", "message"=>"email removed from group"}}
      else
        info = { group_email => {"status"=>"errors", "message"=>"no such email in group"}}
      end
	  return info
	end
end
