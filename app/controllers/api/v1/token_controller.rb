class Api::V1::TokenController < ApplicationController

  # creating a session doesn't require you to have an access token
  skip_before_filter :ensure_authenticated_user, :only => [:get]
  after_filter :render_response
  # Logging the user in
  def get
    user = User.where("cellphone = ?", @params['cellphone']).first
    if user && user.authenticate(@params['password']) && user.activated?
      api_key = user.find_api_key

      if !api_key.is_locked
        api_key.last_access = Time.now

        if !api_key.access_token || api_key["access_token"].empty?
          api_key.set_expiry_date
          api_key.generate_access_token
        end

        api_key.save

        @response_data = api_key.as_json(only: [:access_token])
      else
	    @errors = {"error_text" => "Auth failed", "error_code"=>"AUTH_FAILED", "error_data"=>{"message"=>"your account has been locked."}}
      end

    else
	  @errors = {"error_text" => "Auth failed", "error_code"=>"AUTH_FAILED", "error_data"=>{"message"=>"could not authenticate properly"}}
    end
  end

  # Clearing user key when they log out
  def delete

    api_key = ApiKey.where(access_token: @params['token']).first

    api_key.access_token = ''
    api_key.expires_at = Time.now

    if api_key.save
	  @response_data = {"message"=>"logout complete"}
    else
	  @errors = {"error_text" => "Logout failed", "error_code"=>"LOGOUT_FAILED", "error_data"=>{"message"=>"logout error"}}
    end
  end

end
