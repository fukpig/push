module Yandex

class PDD

	VERSION   = '0.0.1'

	API_URL   = 'https://pddimp.yandex.ru/'

	PDD_TOKEN = 'ZN7YALBAV6KWTPAJOKIFGVOVM5ZRYBV53EUHP6FIRAMOKBCKJWXQ'

	attr_accessor :request, :response
	attr_reader   :error,   :http_error


	def domain_list
		data= {
			:method => 'GET',
			:url => '/api2/admin/domain/domains',
			:params => {}
		}
		result = send_request(data)
		raise ApiError.new("YANDEX error", "YANDEX_ERROR", result["error"]) if result["success"] != "ok"
		return result
	end

	def domain_register(domain_name)
		data= {
			:method => 'POST',
			:url => '/api2/admin/domain/register',
			:params => {:domain => domain_name}
		}
		result = send_request(data)
		raise ApiError.new("YANDEX error", "YANDEX_ERROR", result["error"]) if result["success"] != "ok"
		return result
	end

	def domain_register_status(domain_name)
		data= {
			:method => 'GET',
			:url => '/api2/admin/domain/registration_status',
			:params => {:domain => domain_name}
		}
		result = send_request(data)
		raise ApiError.new("YANDEX error", "YANDEX_ERROR", result["error"]) if result["success"] != "ok"
		return result
	end

	def domain_delegate_status(domain_name)
		data= {
			:method => 'GET',
			:url => '/api2/admin/domain/details',
			:params => {:domain => domain_name}
		}
		result = send_request(data)
		raise ApiError.new("YANDEX error", "YANDEX_ERROR", result["error"]) if result["success"] != "ok"
		return result
	end

	def domain_delete(domain_name)
		data= {
			:method => 'POST',
			:url => '/api2/admin/domain/delete',
			:params => {:domain => domain_name}
		}
		result = send_request(data)
		raise ApiError.new("YANDEX error", "YANDEX_ERROR", result["error"]) if result["success"] != "ok"
		return result
	end


	def email_create(domain_name, login, password)
		data= {
			:method => 'POST',
			:url => '/api2/admin/email/add',
			:params => {:domain => domain_name, :login => login, :password => password}
		}
		result = send_request(data)
		raise ApiError.new("YANDEX error", "YANDEX_ERROR", result["error"]) if result["success"] != "ok"
		return result
	end

	def email_list(domain_name)
		data= {
			:method => 'GET',
			:url => '/api2/admin/email/list',
			:params => {:domain => domain_name}
		}
		result = send_request(data)
		raise ApiError.new("YANDEX error", "YANDEX_ERROR", result["error"]) if result["success"] != "ok"
		return result
	end

	def email_update(domain_name, login, password, action)
		data= {
			:method => 'POST',
			:url => '/api2/admin/email/edit',
			:params => {:domain => domain_name, :login => login, :password => password, :enabled => action}
		}
		result = send_request(data)
		raise ApiError.new("YANDEX error", "YANDEX_ERROR", result["error"]) if result["success"] != "ok"
		return result
	end

	def email_delete(domain_name, login)
		data= {
			:method => 'POST',
			:url => '/api2/admin/email/del',
			:params => {:domain => domain_name, :login => login}
		}
		result = send_request(data)
		raise ApiError.new("YANDEX error", "YANDEX_ERROR", result["error"]) if result["success"] != "ok"
		return result
	end


	def group_create(domain_name, maillist_name)
		data= {
			:method => 'POST',
			:url => '/api2/admin/email/ml/add',
			:params => {:domain => domain_name, :maillist => maillist_name}
		}
		result = send_request(data)
		raise ApiError.new("YANDEX error", "YANDEX_ERROR", result["error"]) if result["success"] != "ok"
		return result
	end

	def group_list(domain_name)
		data= {
			:method => 'GET',
			:url => '/api2/admin/email/ml/list',
			:params => {:domain => domain_name}
		}
		result = send_request(data)
		raise ApiError.new("YANDEX error", "YANDEX_ERROR", result["error"]) if result["success"] != "ok"
		return result
	end

	def group_delete(domain_name, maillist_name)
		data= {
			:method => 'POST',
			:url => '/api2/admin/email/ml/del',
			:params => {:domain => domain_name, :maillist => maillist_name}
		}
		result = send_request(data)
		raise ApiError.new("YANDEX error", "YANDEX_ERROR", result["error"]) if result["success"] != "ok"
		return result
	end

	def group_add_email(domain_name, maillist_name, user_name)
			data= {
			:method => 'POST',
			:url => '/api2/admin/email/ml/subscribe',
			:params => {:domain => domain_name, :maillist => maillist_name, :subscriber => user_name}
		}
		result = send_request(data)
		raise ApiError.new("YANDEX error", "YANDEX_ERROR", result["error"]) if result["success"] != "ok"
		return result
	end

	def group_email_list(domain_name, maillist_name)
			data= {
			:method => 'GET',
			:url => '/api2/admin/email/ml/subscribers',
			:params => {:domain => domain_name, :maillist => maillist_name}
		}
		result = send_request(data)
		raise ApiError.new("YANDEX error", "YANDEX_ERROR", result["error"]) if result["success"] != "ok"
		return result
	end

	def group_del_email(domain_name, maillist_name, user_name)
		data= {
			:method => 'POST',
			:url => '/api2/admin/email/ml/unsubscribe',
			:params => {:domain => domain_name, :maillist => maillist_name, :subscriber => user_name}
		}
		result = send_request(data)
		raise ApiError.new("YANDEX error", "YANDEX_ERROR", result["error"]) if result["success"] != "ok"
		return result
	end

	def group_get_status(domain_name, maillist_name, user_name)
		data= {
			:method => 'POST',
			:url => '/api2/admin/email/ml/get_can_send_on_behalf',
			:params => {:domain => domain_name, :maillist => maillist_name, :subscriber => user_name}
		}
		result = send_request(data)
		raise ApiError.new("YANDEX error", "YANDEX_ERROR", result["error"]) if result["success"] != "ok"
		return result
	end

	def group_set_status(domain_name, maillist_name, user_name, can_send_on_behalf)
		data= {
			:method => 'POST',
			:url => '/api2/admin/email/ml/set_can_send_on_behalf',
			:params => {:domain => domain_name, :maillist => maillist_name, :subscriber => user_name, :can_send_on_behalf => can_send_on_behalf}
		}
		result = send_request(data)
		raise ApiError.new("YANDEX error", "YANDEX_ERROR", result["error"]) if result["success"] != "ok"
		return result
	end



	private
		def send_request(data) 
			if data[:method] == 'GET'
				response = HTTParty.get(API_URL + data[:url],
				  :query => data[:params],
				  :headers => { "PddToken" => PDD_TOKEN	}
	      )
			else 
				response = HTTParty.post(API_URL + data[:url],
				  :query => data[:params],
				  :headers => { "PddToken" => PDD_TOKEN }
				)
			end
			return response.to_hash
		end
	end
end
