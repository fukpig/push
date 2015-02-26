class Api::V1::UsersController < ApplicationController
  

  require 'digest/sha1'
  
  api :GET, "/v1/user/list", "Получить список пользователей"
  param :token, String, :desc => "Пользовательский токен", :required => true
  error :code => 301, :desc => "Invalid token", :meta => {:описание => "Неправильный токен или токен не был передан"}
  
  def list
    authorize! :show, @users
    domain_ids = current_user.domain_ids
	email_list = EmailAccount.list
    show_response(email_list)
  end
  
  
  
  api :GET, "/v1/user/recover", "Восстановление пользователя"
  param :cellphone, String, :desc => "Телефон пользователя", :required => true
  param :device_token, String, :desc => "Токен пользователя", :required => true
  param :recovery_cellphone, String, :desc => "Телефон, который указывался как резервный у доменов", :required => true
  error :code => 301, :desc => "REG_USER_FAILED", :meta => {:описание => "Неправильный телефон или токен девайса"}
  error :code => 301, :desc => "REG_USER_FAILED", :meta => {:описание => "Проблема с SMS gateway"}
  

  def recover
    recovery_hash = generate_user_hash
    device_token = ''
    device_token = @params['device_token'] unless !@params['device_token'].nil?

    if @params['cellphone'] == @params['recovery_cellphone']
      raise ApiError.new("Recover user failed", "RECOVER_USER_FAILED", {'message' => 'Recovery cellphone and cellphone are similar'})
    end

    user = User.where('cellphone = ?', @params['cellphone']).first
    if user 
      raise ApiError.new("Recover user failed", "RECOVER_USER_FAILED", {'message' => 'Cellphone is already used'})
      #user.update_attributes( :recovery_cellphone => @params['recovery_cellphone'], :confirmation_hash => Digest::SHA1.hexdigest(recovery_hash), :action => 'recover', :temp_device_token => @params['device_token']) 
    else 
      user = User.create(cellphone: @params['cellphone'].strip, recovery_cellphone: @params['recovery_cellphone'], confirmation_hash: Digest::SHA1.hexdigest(recovery_hash), device_token: device_token, internal_credit: 5000, action: 'recover')
    end
    if send_reg_sms(@params['recovery_cellphone'], recovery_hash)
        show_response({"message" =>  "SMS successfully sended"})
    end
  end

  def belong_to
    authorize! :show, @users
    roles = UserToCompanyRole.where('user_id = ? and role_id = ?', current_user["id"], 2)
    data = Array.new
    roles.each do |role|
      domain = Domain.where('id = ?', role.domain_id).first
      if domain
        email =  EmailAccount.where('user_id =? and domain_id = ?', current_user["id"], domain.id).first
        data << {"email_id" => email["id"], "email_name" => email["email"], "domain_id" => domain["id"], "domain_name" => domain["domain"]}
      end
    end
    show_response(data)
  end


  api :GET, "/v1/user/info", "Получить информацию о пользователе"
  param :token, String, :desc => "Пользовательский токен", :required => true
  error :code => 301, :desc => "Invalid token", :meta => {:описание => "Неправильный токен или токен не был передан"}
  
  def info
    authorize! :show, @info
    info = current_user.as_json(only: [:id, :name, :cellphone, :email, :user_credential_id, :device_token])
    show_response(info)
  end

  api :GET, "/v1/user/update_info", "Обновление информации о пользователе"
  param :name, String, :desc => "ФИО пользователя", :required => true
  param :device_token, String, :desc => "Токен девайса", :required => true
  error :code => 301, :desc => "REG_USER_FAILED", :meta => {:описание => "Неправильный телефон или токен девайса"}
  

  def update_info
    authorize! :show, @current_user
    if current_user.update_attributes(:name => @params['name']) && !@params['name'].nil?
      EmailAccount.where('user_id = ?', current_user.id).update_all(name: @params['name'], device_token: @params['device_token'])
      show_response({"message" =>  "User successfully updated"})
    else
      raise ApiError.new("update user info failed", "UPDATE_USER_FAILED", "user dont exist or name param is empty")  
    end
  end

  api :GET, "/v1/user/register", "Создание пользователя"
  param :cellphone, String, :desc => "Телефон пользователя", :required => true
  param :device_token, String, :desc => "Токен девайса", :required => true
  error :code => 301, :desc => "REG_USER_FAILED", :meta => {:описание => "Неправильный телефон или токен девайса"}
  error :code => 301, :desc => "REG_USER_FAILED", :meta => {:описание => "Проблема с SMS gateway"}
  
  def register
    confirmation_hash = generate_user_hash
    device_token = ''
    device_token = @params['device_token'] unless !@params['device_token'].nil?
    user = User.where('cellphone = ?', @params['cellphone']).first_or_create(:cellphone => @params['cellphone'].strip, :aasm_state => 'register', :device_token => device_token, :internal_credit => 5000)
    if user.send_sms(confirmation_hash)
		show_response({"message" =>  "SMS successfully sended"})
	else 
	  raise ApiError.new("register user failed", "REG_USER_FAILED", user.errors)
	end
  end



  api :GET, "/v1/user/get_recovery_cellphone", "Получение запасного телефона"
  error :code => 301, :desc => "USER_CONFIRM_FAILED", :meta => {:описание => "Неправильный код подтверждения или пользователь уже активирован"}
  error :code => 301, :desc => "USER_CONFIRM_FAILED", :meta => {:описание => "Пользователь не найден"}
  

  def get_recovery_cellphone
    authorize! :delete, @info
    if current_user.domains.count > 0 
      show_response({"recovery_cellphone"=>current_user.recovery_cellphone})
    else 
      raise ApiError.new("Find recovery cellphone failed", "FIND_REC_CELLPHONE_FAILED", "recovery_cellphone not found")
    end
  end


  api :GET, "/v1/user/confirm", "Подтверждение пользователя по смс"
  param :cellphone, String, :desc => "Телефон пользователя", :required => true
  param :confirm_code, String, :desc => "Код высланный по смс пользователю", :required => true
  error :code => 301, :desc => "USER_CONFIRM_FAILED", :meta => {:описание => "Неправильный код подтверждения или пользователь уже активирован"}
  error :code => 301, :desc => "USER_CONFIRM_FAILED", :meta => {:описание => "Пользователь не найден"}
  
  def confirm
    user = User.where("cellphone = ?", @params['cellphone']).first
	raise ApiError.new("Confirm user failed", "USER_CONFIRM_FAILED", "user not exist or already activated") if !user
	user.check_code(@params['confirm_code'])
	api_key = user.activate
	show_response({"access_token" => api_key['access_token']})
  end

  api :GET, "/v1/user/update_device", "Изменить device_token у пользователя"
  param :device_token, String, :desc => "Токен девайса", :required => true
  param :token, String, :desc => "Пользовательский токен", :required => true
  error :code => 301, :desc => "UPDATE_DEVICE_TOKEN_FAILED", :meta => {:описание => "Проблемы с SMS gateway"}
  error :code => 301, :desc => "UPDATE_DEVICE_TOKEN_FAILED", :meta => {:описание => "Пользователь не найден"}

  def update_device
    authorize! :update, @info
    if current_user.update_attribute( :device_token, @params['device_token'] ) 
      show_response({"message" => "device token updated"})
    else
      raise ApiError.new("Update device token failed", "UPDATE_DEVICE_TOKEN_FAILED", user.errors)
    end
  end
  

  api :GET, "/v1/user/resend_code", "Отправить код подтверждения пользователя заново"
  param :cellphone, String, :desc => "Телефон пользователя", :required => true
  error :code => 301, :desc => "UPDATE_DEVICE_TOKEN_FAILED", :meta => {:описание => "Проблемы с SMS gateway"}
  error :code => 301, :desc => "UPDATE_DEVICE_TOKEN_FAILED", :meta => {:описание => "Пользователь не найден или уже подтвердил код"}
  
  def resend_code
    user = User.where("cellphone = ?", @params['cellphone']).first
    if user && user.activated? == false
	  confirmation_hash = generate_user_hash
	  if user.send_sms(confirmation_hash)
		show_response({"message" =>  "SMS successfully sended"})
	  else 
	    raise ApiError.new("register user failed", "REG_USER_FAILED", user.errors)
	  end
	end
  end
  
  #TODO DESTROY IN PRODUCTION
  def delete_by_phone
      user = User.where("cellphone = ?", @params['cellphone']).first
       user.destroy
       if user.destroyed?
         show_response({"message"=>"User successfully delete"})
       else
         raise ApiError.new("Delete user failed", "DEL_DOMAIN_FAILED", user.errors)
       end
  end

  api :GET, "/v1/user/to_balance", "Пополнить внутренний баланс"
  param :amount, String, :desc => "Сумма пополнения", :required => true
  error :code => 301, :desc => "UPDATE_DEVICE_TOKEN_FAILED", :meta => {:описание => "Проблемы с SMS gateway"}
  error :code => 301, :desc => "UPDATE_DEVICE_TOKEN_FAILED", :meta => {:описание => "Пользователь не найден или уже подтвердил код"}
 

  def to_balance
    authorize! :update, @info
    current_user.to_credit(@params['amount'].to_f)
    show_response({"message"=>"Balance successfully added"})
  end

  api :GET, "/v1/user/balance", "Вывод внутреннего баланса"


  def balance
    authorize! :update, @info
    show_response(current_user.internal_credit)
  end

  api :GET, "/v1/user/get_subscriptions", "Получить список подписок"

  def get_subscriptions
    authorize! :update, @info
    show_response(current_user.billing_subscriptions.as_json(only: [:id, :type_of, :subscription_date, :previous_billing_date, :next_billing_date]))
  end

  api :GET, "/v1/user/get_cost_subscription", "Стоимость подписки"
  param :subscription_id, String, :desc => "Id подписки", :required => true

  def get_cost_subscription
    authorize! :update, @info
    subscription = current_user.billing_subscription.find(@params['subscription_id'])
    domain = Domain.find(subscription.domain)
    show_response(current_user.get_full_amount(subscription.type_of, domain))
  end

  api :GET, "/v1/user/bill_domain", "Оплатить домен"
  param :domain, String, :desc => "Домен подписки", :required => true

  def bill_domain
    authorize! :update, @info
    subscription = current_user.billing_subscription.where('type_of = ? and domain =?', 'domain', @params['domain']).first
    subscription.bill
    show_response("message"=>"successfully added payment")
  end

  api :GET, "/v1/user/bill_mailboxes", "Оплатить ящики на домене"
  param :domain, String, :desc => "Домен подписки", :required => true

  def bill_mailboxes
    authorize! :update, @info
    subscription = current_user.billing_subscription.where('type_of = ? and domain =?', 'email', @params['domain']).first
    subscription.bill
    show_response("message"=>"successfully added payment")
  end


  api :GET, "/v1/user/check_phone", "Проверка правильности ввода и получение кода страны"
  def check_phone
    GlobalPhone.db_path = Rails.root.join('db/global_phone.json')

    phone = "+" + @params['cellphone']
    number = GlobalPhone.parse(phone)
    show_response({"valid"=>GlobalPhone.validate(phone), "territory" => number.territory.name})
  end

  
  api :GET, "/v1/user/test_push_ios", "Тестовый метод отправки push-а для ios"
  param :token, String, :desc => "Пользовательский токен", :required => true
  
  def test_push_ios
    authorize! :show, @info
    send_ios_notify(current_user.device_token, 'Hello iPhone!')
  end


  api :GET, "/v1/user/test_push_android", "Тестовый метод отправки push-а для android-а"
  param :token, String, :desc => "Пользовательский токен", :required => true

  def test_push_android
    authorize! :show, @info
    send_android_notify(current_user.device_token, {:hello => "world"})
  end

end
