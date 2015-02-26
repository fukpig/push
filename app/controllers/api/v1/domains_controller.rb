class Api::V1::DomainsController < ApplicationController
  require 'yandex'
  include ActionController::Live

  api :GET, "/v1/domain/list", "Получить список доменов"
  param :token, String, :desc => "Пользовательский токен", :required => true
  error :code => 301, :desc => "Invalid token", :meta => {:описание => "Неправильный токен или токен не был передан"}
  
  def list
    authorize! :show, @users
    show_response(Domain.list(current_user))
  end

  api :GET, "/v1/domain/info", "Получить информацию о домене"
  param :token, String, :desc => "Пользовательский токен", :required => true
  param :domain_id, String, :desc => "Id домена", :required => true
  error :code => 301, :desc => "Invalid token", :meta => {:описание => "Неправильный токен или токен не был передан"}
  error :code => 301, :desc => "FIND_DOMAIN_FAILED", :meta => {:описание => "Домен не найден"}
  
  def info
    authorize! :show, @domain
	#TO-DO
    check_owner(@params['domain_id'])
   
    domain = current_user.domains.find( @params['domain_id'])
	show_response(domain.as_json(only: [:id, :domain, :registration_date, :expiry_date, :status]))
  end

  

  api :GET, "/v1/domain/create", "Создать домен(пока локально)"
  param :token, String, :desc => "Пользовательский токен", :required => true
  param :domain, String, :desc => "Домен", :required => true
  param :cellphone, String, :desc => "Телефон", :required => true
  error :code => 301, :desc => "Invalid token", :meta => {:описание => "Неправильный токен или токен не был передан"}
  error :code => 301, :desc => "REG_DOMAIN_FAILED", :meta => {:описание => "Не передан один из параметров"}
  
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

  api :GET, "/v1/domain/delete", "Удалить домен(пока локально)"
  param :token, String, :desc => "Пользовательский токен", :required => true
  param :domain_id, String, :desc => "ID домена", :required => true
  error :code => 301, :desc => "Invalid token", :meta => {:описание => "Неправильный токен или токен не был передан"}
  error :code => 301, :desc => "DEL_DOMAIN_FAILED", :meta => {:описание => "Домен не найден"}
  
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
    list = Array.new
    domains = DelegatedDomain.where(["to = ?", current_user.id])
    domains.each do |domain|
      list << add_domain_to_list(domain) unless domain.accepted?
    end
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
  
  api :GET, "/v1/invite/reject", "Отклонить инвайт"
  param :token, String, :desc => "Пользовательский токен", :required => true
  param :invite_id, String, :desc => "Id инвайта", :required => true
  error :code => 301, :desc => "Invalid token", :meta => {:описание => "Неправильный токен или токен не был передан"}
  def reject
    authorize! :destroy, @invites
    delegate = DelegatedDomain.get_delegate_invite(user_id, )
    if delegate.destroyed?
      show_response({"message"=>"Delegate successfully reject"})
    else 
      raise ApiError.new("Reject invite failed", "REJECT_INVITE_FAILED", delegate.errors)
    end
  end




  def add_domain_to_list(domain)
    info = Hash.new
    domain = Domain.where(["id = ?", domain["domain_id"]]).first
    inviter = User.where(["id = ?", domain["inviter_id"]]).first
    info = { "id" => domain["id"], "domain_id" => domain["domain_id"], "domain"=> domain["domain"], "inviter_id" => domain["inviter_id"], "inviter_name" => domain["name"]}
  end


  api :GET, "/v1/domain/check_available", "Проверить доступность домена для регистрации(+ автоматом возвращает доступные варианты доменов с reg.ru)"
  param :domain, String, :desc => "Домен", :required => true
  error :code => 301, :desc => "CHECK_DOMAIN_FAILED", :meta => {:описание => "Неправильный домен"}
  
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


  api :GET, "/v1/domain/get_register_price", "Проверить доступность домена для регистрации(+ автоматом возвращает доступные варианты доменов с reg.ru)"
  param :domain, String, :desc => "Домен", :required => true
  param :token, String, :desc => "Токен", :required => true
  error :code => 301, :desc => "CHECK_DOMAIN_FAILED", :meta => {:описание => "Неправильный домен"}
  
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


  #def test_async
    #response.headers['Content-Type'] = 'text/event-stream'
    #word = @params['word']
    #zones = PsConfigZones.all
    #zones.each do |zone|
      #begin
        #domain = word + "." + zone.name
        #result = Whois.whois(domain)
        #if !result.nil? and result.available? == true
        #  status = 'AVAILABLE'
        #else 
        #  status = 'NOT AVAILABLE'
        #end
        #response.stream.write zone.name + " ==>"+ status +"\n"
      #rescue => e
        #puts "Error #{e}"
        #next   # <= This is what you were looking for
      #end
    #end
    #response.stream.close
  #end

  private 

  #def check_domain_valid(domain_zone, domain, domain_word)
    #if domain_zone.nil? && !domain_zone && !domain.match("^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}$")
        #raise ApiError.new("domain is not available", "CHECK_DOMAIN_FAILED", {"message" => get_domains_variants(domain_word)})
    #end
  #end

  def check_owner(domain_id)
     raise ApiError.new("no such domain", "NO_SUCH_DOMAIN", "no such domain") unless current_user.domains.where(["id = ?", @domain_id]).present?
  end
end
