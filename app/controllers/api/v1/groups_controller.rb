class Api::V1::GroupsController < ApplicationController


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

  def check
    authorize! :update, @email
    group = Group.where("email = ?", @params['group_name']).first
    if !group
      show_response({"message"=>"Group available"})
    else
      raise ApiError.new("group not available", "CHECK_GROUP_FAILED", {"message" => 'group not available'})
    end
  end


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

  def add
    authorize! :create, @group
    info = EmailAccount.split_email(@params['mail'])
    domain = current_user.domains.where('domain = ?', info['domain']).first
    group = Group.where(["email = ? AND domain_id = ?", @params['mail'] ,domain['id']]).first   
        
	info = edit_group(domain, group, @params['group_emails'], 'add')
    show_response(info)
  end

  def remove
    authorize! :create, @group
    info = EmailAccount.split_email(@params['mail'])
    domain = current_user.domains.where('domain = ?', info['domain']).first
    group = Group.where(["email = ? AND domain_id = ?", @params['mail'] ,domain['id']]).first
	
	info = edit_group(domain, group, @params['group_emails'], 'del')
	show_response(info)
  end

end