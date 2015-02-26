class Api::V1::EmailaccountsController < ApplicationController
  include EmailHelper
  require 'yandex'

  def info
    authorize! :show, @email
	domain = current_user.domains.where(["id = ?", @params['domain_id']]).first
    raise ApiError.new("find email failed", "SHOW_EMAIL_FAILED", "domain not found") if domain.nil?
    if EmailAccount.where(["id = ?", @params['email_id']]).present?
      email = EmailAccount.find( @params['email_id'])
      emails.as_json(email.as_json(only: [:id, :email]))
    else
      raise ApiError.new("find email failed", "SHOW_EMAIL_FAILED", "no such email")
    end
  end

  def create
    authorize! :create, @email
    EmailAccount.transaction do
      current_user.check_balance(5)
      info = EmailAccount.split_email(@params['mail'])
      domain = current_user.domains.where('domain = ?', info['domain']).first
      email = EmailAccount.create_email(current_user, domain['id'], info['email_name'], 'user', @params['name'])
      #YANDEX
        #pdd = init_pdd
        #password = Array.new(10){[*"A".."Z", *"0".."9"].sample}.join
        #pdd.email_create(domain['domain'], info['email_name'], password)
      #YANDEX

      #SEND INVITE

       data = {'user_id'   =>current_user['id'], 
			   'cellphone' => @params['invite_cellphone'], 
			   'domain_id' => domain['id'], 
			   'email_id'  => email['id'], 
			   'name' => @params['name']}
       Invite.create_invite(data)
		
      #SEND INVITE

      interval = 1
      interval = @params['interval'].to_i unless @params['interval'].nil?
      current_user.pay_email(domain.id, interval)
      show_response(email.as_json(only: [:id, :email]))
    end
  end

  def delete
    authorize! :destroy, @email
    email = EmailAccount.where(["email = ?", @params['email']]).first
    raise ApiError.new("Delete email failed", "DEL_EMAIL_FAILED", "no such email") if email.nil?
    
	email.destroy
    if email.destroyed?
         #YANDEX
         data = EmailAccount.split_email(@params['email'])
         #pdd = init_pdd()
         #pdd.email_delete(data['domain'], data['email_name'])
         #YANDEX
       show_response({"message"=>"email successfully delete"})
    else
      raise ApiError.new("Delete email failed", "DEL_EMAIL_FAILED", email.errors)
    end

  end

  def check
    authorize! :update, @email
    email = EmailAccount.where("email = ?", @params['email'].downcase).first
    if !email
      show_response({"message"=>"Email available"})
    else
      info = EmailAccount.split_email(@params['email'].downcase)
      data = {:firstname => @params["firstname"], :phone => @params["cellphone"], :domain => info["domain"], :email => info["email_name"]}
      emails = generate_email(data)
      raise ApiError.new("email not available", "CHECK_EMAIL_FAILED", {"message" => emails})
    end
  end

  def hold_to_admin
     authorize! :update, @email
     email = EmailAccount.where('email = ?', @params["email"]).first
	 domain = current_user.domains.where('id =?', email.domain_id).first
     raise ApiError.new("email not available", "CHECK_EMAIL_FAILED", {"message" => emails}) if domain.nil?
     
	 if email.update_attribute(user_id: current_user.id)
        show_response({"message"=>"Ok"})
	 end
  end

  def enable
    authorize! :update, @email
    email = current_user.email_accounts.where(["email = ?", @params['email']]).first
    raise ApiError.new("enable email failed", "ENABLE_EMAIL_FAILED", "no such email") if email.nil?
    if email.update_attributes(is_enabled: true)
      show_response({"message"=>"email successfully enabled"})
    else
      raise ApiError.new("enable email failed", "ENABLE_EMAIL_FAILED", email.errors)
    end
  end

  def disable
    email = current_user.email_accounts.where(["email = ?", @params['email']]).first
    raise ApiError.new("enable email failed", "ENABLE_EMAIL_FAILED", "no such email") if email.nil?
    if email.update_attributes(is_enabled: false)
      show_response({"message"=>"email successfully disabled"})
    else
      raise ApiError.new("enable email failed", "ENABLE_EMAIL_FAILED", email.errors)
    end
  end

  def change_password
    email = current_user.email_accounts.where(["email = ?", @params['email']]).first
    raise ApiError.new("change password failed", "CHANGE_PASSWORD_FAILED", "no such email") if email.nil?
    if Yandex.updatepassword
      show_response({"message"=>"password successfully changed"})
    else
      raise ApiError.new("change password failed", "CHANGE_PASSWORD_FAILED", email.errors)
    end
  end
  
  def get_email_price()
    authorize! :update, @email
    show_response({'per_day' => EmailAccount.amount_per_day, 'full_month' => 5})
  end
end
