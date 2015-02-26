class Api::V1::DomainsController < ApplicationController
  require 'yandex'
  include ActionController::Live
 
  def list
    authorize! :show, @users
    show_response(Domain.list(current_user))
  end

  def info
    authorize! :show, @domain
	#TO-DO
    check_owner(@params['domain_id'])
   
    domain = current_user.domains.find( @params['domain_id'])
	show_response(domain.as_json(only: [:id, :domain, :registration_date, :expiry_date, :status]))
  end


  def create
    authorize! :create, @domain
    info = EmailAccount.split_email(@params['domain'])
	current_user.set_recovery_cellphone(@params['celllphone'])
	domain = Domain.register(current_user, info)
	if !domain.nil?
	  show_response(domain.as_json(only: [:id, :domain, :registration_date, :expiry_date, :status, :ns_list]))
	else 
	  raise ApiError.new("Register domain failed", "REG_DOMAIN_FAILED", 'errors')
	end
	
  end

  def delete
    authorize! :delete, @users
    check_owner
    
    domain = Domain.find(@params['domain_id'])
    domain.destroy
    if domain.destroyed?
		  show_response({"message"=>"domain successfully delete"})
    else
      raise ApiError.new("Delete domain failed", "DEL_DOMAIN_FAILED", domain.errors)
    end
  end


  def delegate
    authorize! :delete, @users
    check_owner(@params["domain_id"])
    
    data = {'domain_id'=>current_user['id'], 'from' => current_user["id"], 'to' => @params['to']}
    result = DelegatedDomain.delegate(data)
    show_response(result)
  end

  def delegated_domain_to_me
    authorize! :show, @invites
    list = Domain.get_invite_domains(current_user, 'domains')
    show_response(list)
  end

   def accept
    authorize! :update, @invites
	delegate = DelegatedDomain.get_delegate_invite(user_id, )
    
	if delegate.accept
        domain = Domain.find(delegate.domain_id)
        domain.change_owner(current_user.id)
		EmailAccount.change_owner(domain.id)
        show_response({"message"=>"successfully added to company"})
    else 
        raise ApiError.new("Accept invite failed", "ACCEPT_INVITE_FAILED", delegate.errors)
    end
  end

  def reject
    authorize! :destroy, @invites
    delegate = DelegatedDomain.get_delegate_invite(user_id, )
    if delegate.destroyed?
      show_response({"message"=>"Delegate successfully reject"})
    else 
      raise ApiError.new("Reject invite failed", "REJECT_INVITE_FAILED", delegate.errors)
    end
  end


  def check_available
    result = Domain.whois(@params['domain'])
  	if result.available? == false
  		info = Domain.parse_domain(@params['domain'])
  		reg_ru = RegApi2.domain.get_suggest(word: info['domain_word'],
  			use_hyphen: "1"
  		)
  		show_response({"available"=>result.available?, "choice" => reg_ru})
  	else 
  		show_response({"available"=>result.available?})
  	end
  end
  
  def get_register_price
    authorize! :show, @info

    domain = SimpleIDN.to_ascii(@params['domain'])
	price = Domain.get_price(domain)
    if !price["domain_price"].nil?
	 show_response(price)
	else 
	  raise ApiError.new("domain is not available", "CHECK_DOMAIN_FAILED", {"message" => Domain.get_variants(domain)})
	end
  end


  private 

  def check_owner(domain_id)
     raise ApiError.new("no such domain", "NO_SUCH_DOMAIN", "no such domain") unless current_user.domains.where(["id = ?", @domain_id]).present?
  end
end
