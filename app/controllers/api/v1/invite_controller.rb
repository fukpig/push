class Api::V1::InviteController < ApplicationController
 
  api :GET, "/v1/invite/create", "Создание инвайта"
  param :token, String, :desc => "Пользовательский токен", :required => true
  param :domain_id, String, :desc => "Id домена", :required => true
  param :cellphone, String, :desc => "Телефон юзера, которого приглашаем", :required => true
  error :code => 301, :desc => "Invalid token", :meta => {:описание => "Неправильный токен или токен не был передан"}

  def create
  	#TODO REFACT THIS IF`s
  	authorize! :create, @invite

    data = {'user_id'=>current_user['id'], 'cellphone' => @params['cellphone'], 'domain_id' => @params['domain_id'], 'email_id' => @params['email_id'], 'name' => @params['name']}
  	result = Invite.create_invite(data)
    show_response(result)
  end

  api :GET, "/v1/invite/list", "Список инвайтов вылсанных на те"
  param :token, String, :desc => "Пользовательский токен", :required => true
  param :domain_id, String, :desc => "Id домена", :required => true
  param :cellphone, String, :desc => "Телефон юзера, которого приглашаем", :required => true
  error :code => 301, :desc => "Invalid token", :meta => {:описание => "Неправильный токен или токен не был передан"}


  def list
  	authorize! :show, @invites
	list = Array.new
	invites = Invite.where(["cellphone = ?", current_user.cellphone])
	invites.each do |invite|
	  list << Domain.add_to_list(invite) unless invite.accepted?
	end
	show_response(list)
  end

  api :GET, "/v1/invite/accept", "Принять инвайт"
  param :token, String, :desc => "Пользовательский токен", :required => true
  param :invite_id, String, :desc => "Id инвайта", :required => true
  error :code => 301, :desc => "Invalid token", :meta => {:описание => "Неправильный токен или токен не был передан"}

  def accept
  	authorize! :update, @invites
	invite = Invite.where(["cellphone = ? and id=?",current_user["cellphone"], @params["invite_id"]]).first
	raise ApiError.new("Accept invite failed", "ACCEPT_INVITE_FAILED", "no such invite") if invite.nil?
	if invite.update_attribute( :accepted, true ) 
	  add_user_to_company(2, invite["domain_id"])
      email = EmailAccount.find(invite['email_id'])
      email.update_attributes(:user_id => current_user['id'], :name => invite['name'])
	  show_response({"message"=>"successfully added to company"})
	else 
      raise ApiError.new("Accept invite failed", "ACCEPT_INVITE_FAILED", invite.errors)
	end
  end
  
  api :GET, "/v1/invite/reject", "Отклонить инвайт"
  param :token, String, :desc => "Пользовательский токен", :required => true
  param :invite_id, String, :desc => "Id инвайта", :required => true
  error :code => 301, :desc => "Invalid token", :meta => {:описание => "Неправильный токен или токен не был передан"}
  def reject
  	authorize! :destroy, @invites
	invite = Invite.where(["cellphone = ? and id=?",current_user["cellphone"], @params["invite_id"]]).first
	raise ApiError.new("Accept invite failed", "ACCEPT_INVITE_FAILED", "no such invite") if invite.nil?
	if invite.destroyed?
	  show_response({"message"=>"Invite successfully reject"})
	else 
      raise ApiError.new("Reject invite failed", "REJECT_INVITE_FAILED", invite.errors)
	end
  end

end
