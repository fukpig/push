class Api::V1::GroupsController < ApplicationController

  api :GET, "/v1/group/list", "Получить список групп"
  param :token, String, :desc => "Пользовательский токен", :required => true
  error :code => 301, :desc => "Invalid token", :meta => {:описание => "Неправильный токен или токен не был передан"}

  def list
    authorize! :show, @groups
    domain_ids = current_user.domain_ids
    groups = Group.where("domain_id IN (?)", domain_ids)
    info = Array.new()
    groups.each do |group|
      domain = Domain.where('id = ?', group["domain_id"]).first
      if domain 
        info << { "id" => group['id'], 'email' => group['email'], "description" => group['description']}
      end
    end
    show_response(info)
  end

  api :GET, "/v1/group/check", "Проверить и сгенерировать группу"
  param :token, String, :desc => "Пользовательский токен", :required => true
  param :group_name, String, :desc => "Ящик", :required => true
  error :code => 301, :desc => "Invalid token", :meta => {:описание => "Неправильный токен или токен не был передан"}

  def check
    authorize! :update, @email
    group = Group.where("email = ?", @params['group_name']).first
    if !group
      show_response({"message"=>"Group available"})
    else
      raise ApiError.new("group not available", "CHECK_GROUP_FAILED", {"message" => 'group not available'})
    end
  end



  api :GET, "/v1/group/info", "Получить информацию о группе"
  param :token, String, :desc => "Пользовательский токен", :required => true
  param :mail, String, :desc => "Наименование группы", :required => true
  error :code => 301, :desc => "Invalid token", :meta => {:описание => "Неправильный токен или токен не был передан"}

  def info
    info = EmailAccount.split_email(@params['mail'])
    domain = current_user.domains.where('domain = ?', info['domain']).first
    raise ApiError.new("show group failed", "SHOW_GROUP_FAILED", "domain not found") if domain.nil?
    group = Group.where(["email = ? AND domain_id = ?", @params['mail'] ,domain['id']]).first
    if group 
      show_response({'id' => group['id'], 'email' => group['email'], 'description' => group['description'], 'emails' => group.email_accounts, 'created_at' => group["created_at"].strftime("%d.%m.%Y")})
    else
      raise ApiError.new("show group failed", "SHOW_GROUP_FAILED", "group not found")
     end
  end

  api :GET, "/v1/group/create", "Создание группы"
  param :token, String, :desc => "Пользовательский токен", :required => true
  param :mail, String, :desc => "Наименование группы", :required => true
  param :description, String, :desc => 'Описание группы', :required => true
  error :code => 301, :desc => "Invalid token", :meta => {:описание => "Неправильный токен или токен не был передан"}

  def create
    authorize! :create, @group
    info = EmailAccount.split_email(@params['mail'])
    domain = current_user.domains.where('domain = ?', info['domain']).first
    group = Group.create(domain_id: domain['id'], email: @params['mail'], description: @params['description'])
    if !group.new_record?
      show_response(group.as_json(only: [:id, :email]))
    else
       raise ApiError.new("Register group failed", "CREATE_GROUP_FAILED", group.errors)
    end
  end

  api :GET, "/v1/group/delete", "Удаление группы"
  param :token, String, :desc => "Пользовательский токен", :required => true
  param :mail, String, :desc => "Наименование группы", :required => true
  param :group_id, String, :desc => "Id группы", :required => true
  error :code => 301, :desc => "Invalid token", :meta => {:описание => "Неправильный токен или токен не был передан"}


  def delete
    authorize! :destroy, @email
    info = EmailAccount.split_email(@params['mail'])
    domain = current_user.domains.where('domain = ?', info['domain']).first
	group = Group.where(["email = ? AND domain_id = ?", @params['mail'] ,domain['id']]).first
    raise ApiError.new("Delete group failed", "DEL_GROUP_FAILED", "no such domain") if group.nil?
    
	group.destroy
    if group.destroyed?
      show_response({"message"=>"Group successfully delete"})
    else
      raise ApiError.new("Delete group failed", "DEL_GROUP_FAILED", group.errors)
    end
  end

  api :GET, "/v1/group/add", "Добавление ящиков в группу"
  param :token, String, :desc => "Пользовательский токен", :required => true
  param :mail, String, :desc => "Id домена", :required => true
  param :group_emails, String, :desc => "Массив с наименованиями ящиков вида test@test.ru", :required => true
  error :code => 301, :desc => "Invalid token", :meta => {:описание => "Неправильный токен или токен не был передан"}

  def add
    authorize! :create, @group
    info = EmailAccount.split_email(@params['mail'])
    domain = current_user.domains.where('domain = ?', info['domain']).first
    group = Group.where(["email = ? AND domain_id = ?", @params['mail'] ,domain['id']]).first
    
	raise ApiError.new("Add emails to group failed", "ADD_EMAILS_TO_GROUP_FAILED", "no such domain or group") if group.nil?
    raise ApiError.new("Add emails to group failed", "ADD_EMAILS_TO_GROUP_FAILED", "emails array empty") if !@params['group_emails'].nil?
        
	info = []
    @params['group_emails'].each do |group_email|
      group_info = EmailAccount.split_email(group_email)
      email = EmailAccount.where('email = ?', group_email).first
	  info << Group.add_email(group, domain, email)
    end
    show_response(info)
  end

  api :GET, "/v1/group/remove", "Удаление ящиков из группы"
  param :token, String, :desc => "Пользовательский токен", :required => true
  param :mail, String, :desc => "Id домена", :required => true
  param :group_emails, String, :desc => "Массив с наименованиями ящиков вида test@test.ru", :required => true
  error :code => 301, :desc => "Invalid token", :meta => {:описание => "Неправильный токен или токен не был передан"}

  def remove
    authorize! :create, @group
    info = EmailAccount.split_email(@params['mail'])
    domain = current_user.domains.where('domain = ?', info['domain']).first
    group = Group.where(["email = ? AND domain_id = ?", @params['mail'] ,domain['id']]).first
	
	raise ApiError.new("Add emails to group failed", "ADD_EMAILS_TO_GROUP_FAILED", "no such domain or group") if group.nil?
    raise ApiError.new("Add emails to group failed", "ADD_EMAILS_TO_GROUP_FAILED", "emails array empty") if !@params['group_emails'].nil?
        
    @params['group_emails'].each do |group_email|
      group_info = EmailAccount.split_email(group_email)
      email = EmailAccount.where('email = ?', group_email).first
      info << Group.del_email(group, domain, email)
    end
    show_response(info)
  end

end