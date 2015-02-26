class Api::V1::CompaniesController < ApplicationController
  after_filter :render_response

  def list
    companies = current_user.companies
	@response_data = companies.as_json(only: [:id, :name])
  end

  def info
    info = Hash.new

    if current_user.companies.where(["id = ?", @params['company_id']]).present?
      company = current_user.companies.find(@params['company_id'])
	  @response_data = company.as_json(only: [:id, :name])
    else
	  @errors = {"error_text" => "no such company", "error_code"=>"FIND_COMPANY_FAILED", "error_data"=>{"message"=>"no such company"}}
    end
  end

  def create
    info = Hash.new

    company = Company.create(user_id: current_user['id'], name: @params['name'])
    
    if !company.new_record?
      #user have to  master status on this company
      UserToCompanyRole.create(user_id: current_user['id'],role_id:1, company_id: company['id'])
	  @response_data = company.as_json(only: [:id, :name])
    else
	  @errors = {"error_text" => "create company failed", "error_code"=>"CREATE_COMPANY_FAILED", "error_data"=>company.errors}
    end
  end

  def delete
    info = Hash.new

    if current_user.companies.where(["id = ?", @params['company_id']]).present?
      company = Company.find(@params['company_id'])
      company.destroy
      if company.destroyed?
	    @response_data = {"message"=>"company successfully delete"}
      else
	    @errors = {"error_text" => "delete company failed", "error_code"=>"DELETE_COMPANY_FAILED", "error_data"=>company.errors}
      end
    else
	  @errors = {"error_text" => "delete company failed", "error_code"=>"DELETE_COMPANY_FAILED", "error_data"=>{"message"=>"no such company"}}
    end
  end

 def update
    info = Hash.new
    if current_user.companies.where(["id = ?", @params['company_id']]).present?
      company = Company.find(@params['company_id'])
      if company.update_attributes(name: @params['name'])
	    @response_data = {"message"=>"company successfully update"}
      else
	     @errors = {"error_text" => "update company failed", "error_code"=>"UPDATE_COMPANY_FAILED", "error_data"=>company.errors}
      end
    else
	   @errors = {"error_text" => "update company failed", "error_code"=>"UPDATE_COMPANY_FAILED", "error_data"=>{"message"=>"no such company"}}
    end
  end
end
