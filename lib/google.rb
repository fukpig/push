class GOOGLE
  require 'google/api_client'
  require 'google/api_client/client_secrets'
  require 'google/api_client/auth/installed_app'


  def get_google_client(scope)
    client = Google::APIClient.new(
        :application_name => 'ps application',
        :application_version => '1.0.0'
    )

    key = Google::APIClient::KeyUtils.load_from_pkcs12('/home/api-ps/config/new-ps-56ae1af9a68a.p12', 'notasecret')
    client.authorization = Signet::OAuth2::Client.new(
       :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
       :audience => 'https://accounts.google.com/o/oauth2/token',
       :scope => scope,
       :issuer => '894085295681-o692a2bnh4spgcs9glr5cva2s4ughkdq@developer.gserviceaccount.com',
       :person => 'rinat@reseller.exod.co.uk',
       :signing_key => key)
 
    client.authorization.fetch_access_token!

    return client
  end

  

  def create_domain_in_gapps(data)
    	client = get_google_client('https://www.googleapis.com/auth/apps.order')
    	reseller = client.discovered_api('reseller')

      body_data = 
       {
        'kind' => 'reseller#customer',
        'customerId' => data[:domain],
        'customerDomain' => data[:domain],
        'postalAddress' => {
          'kind' => 'customers#address',
          'contactName' => 'Test testov test',
          'organizationName' => 'Test company',
          'locality' => 'Almaty',
          'region' => 'Almaty',
          'postalCode' => '050000',
          'countryCode' => 'KZ',
          'addressLine1' => 'Ulitsa Pushkina',
          'addressLine2' => 'Ulitsa Pushkina',
          'addressLine3' => 'Ulitsa Pushkina'
         },
        'phoneNumber' => '+77772727454',
        'alternateEmail' => 'altermail@mail.ru',
        'resourceUiUrl' => ''
      }

      #Create customer
      result = client.execute(
          :api_method => reseller.customers.insert,
          :body_object => body_data,
      )
      raise StandardError.new(message:result.data["error"]["message"]) unless result.status == 200
      result.data
  end

  def create_subscription_google(data)
    body_data = {
      'customerId'=>data[:domain],
      'plan'=> {
        'planName'=>'FLEXIBLE',
        'isCommitmentPlan'=> 'false'
       }, 
       'kind'=>'reseller#subscription',
       'subscriptionId'=>'1234',
       'skuId'=>'Google-Apps-For-Business',
       'seats'=> {
         'maximumNumberOfSeats'=> 5,
         'numberOfSeats'=> 5,
         'kind'=>'subscriptions#seats'
       }
    }
    #Create subscription
    result = client.execute(
        :api_method => reseller.subscriptions.insert,
        :parameters => {:customerId => data[:domain]},
        :body_object => body_data,
    )
    raise StandardError.new(message:result.data["error"]["message"]) unless result.status == 200
    result.data
  end

  def change_renewal_settings_google(data)
    body_data = {
      "kind" => "subscriptions#renewalSettings",
      "renewalType" => "RENEW_CURRENT_USERS_MONTHLY_PAY"
    }

    result = client.execute(
        :api_method => reseller.subscriptions.change_renewal_settings,
        :parameters => {:customerId => data[:domain], :subscriptionId => data[:subscriptionId]},
        :body_object => body_data,
    )

    raise StandardError.new(message:result.data["error"]["message"]) unless result.status == 200
    result.data
  end

  def activate_subscription_google(data)
    result = client.execute(
        :api_method => reseller.subscriptions.activate,
        :parameters => {:customerId => data[:domain], :subscriptionId => data[:subscriptionId]},
    )

    raise StandardError.new(message:result.data["error"]["message"]) unless result.status == 200
    result.data
  end

  def change_seats_google(data)
    body_data = {
      "kind" => "subscriptions#seats",
      "maximumNumberOfSeats" => data[:max_seats],
      "numberOfSeats" => data[:number_seats],
    }

    result = client.execute(
        :api_method => reseller.subscriptions.change_renewal_settings,
        :parameters => {:customerId => data[:domain], :subscriptionId => data[:subscriptionId]},
        :body_object => body_data,
    )

    raise StandardError.new(message:result.data["error"]["message"]) unless result.status == 200
    result.data
  end

  def suspend_subscription_google(data)
    result = client.execute(
        :api_method => reseller.subscriptions.suspend,
        :parameters => {:customerId => data[:domain], :subscriptionId => data[:subscriptionId]},
    )

    raise StandardError.new(message:result.data["error"]["message"]) unless result.status == 200
    result.data
  end

  def subscription_list_google(data)
    result = client.execute(
        :api_method => reseller.subscriptions.list,
        :parameters => {},
    )

    raise StandardError.new(message:result.data["error"]["message"]) unless result.status == 200
    result.data
  end

  def delete_subscription_google(data)
    result = client.execute(
        :api_method => reseller.subscriptions.delete,
        :parameters => {:customerId => data[:domain], :subscriptionId => data[:subscriptionId], :deletionType => 'suspend'},
    )

    raise StandardError.new(message:result.data["error"]["message"]) unless result.status == 200
    result.data
  end

  def create_google_email(data)
  	client = get_google_client('https://www.googleapis.com/auth/admin.directory.user')
  	admin = client.discovered_api('admin', 'directory_v1')

  	body_data = {
 	  "name"=> {
        "familyName"=> "test",
        "givenName"=> "test"
      },
      "password"=> data[:password],
      "primaryEmail"=> data[:email],
      "customerId"=> data[:domain]
    }

	  result = client.execute(
        :api_method => admin.users.insert,
        :body_object => body_data,
    )

    raise StandardError.new(message:result.data["error"]["message"]) unless result.status == 200
    result.data
  end

  def delete_google_email(data)
  	client = get_google_client('https://www.googleapis.com/auth/admin.directory.user')
  	admin = client.discovered_api('admin', 'directory_v1')

  	result = client.execute(
        :api_method => admin.users.delete,
        :parameters => {:userKey => data[:email]},
    )

    raise StandardError.new(message:result.data["error"]["message"]) unless result.status == 200
    result.data
  end

  def create_alias_google_email(data)
  	client = get_google_client('https://www.googleapis.com/auth/admin.directory.user.alias')
  	admin = client.discovered_api('admin', 'directory_v1')
  	body_data = {
	    "kind" => "admin#directory#alias",
	    "alias" => data[:alias_name]
	  }
	  result = client.execute(
        :api_method => admin.users.aliases.insert,
        :parameters => {:userKey => data[:email]},
        :body_object => body_data,
    )

    raise StandardError.new(message:result.data["error"]["message"]) unless result.status == 200
    result.data
  end

  def delete_alias_google_email(data)
  	client = get_google_client('https://www.googleapis.com/auth/admin.directory.user.alias')
  	admin = client.discovered_api('admin', 'directory_v1')
	  result = client.execute(
        :api_method => admin.users.aliases.delete,
        :parameters => {:userKey => data[:email], :alias => data[:alias_name]},
    )
    raise StandardError.new(message:result.data["error"]["message"]) unless result.status == 200
    result.data
  end

  def create_group_google(data)
  	client = get_google_client('https://www.googleapis.com/auth/admin.directory.group')
  	admin = client.discovered_api('admin', 'directory_v1')

  	body_data = {
 	    "email" => data[:group_name],
      "id" => "65466",
 	    "kind" => "admin#directory#group",
  	  "name" => data[:group_name]
	  }

	  result = client.execute(
        :api_method => admin.groups.insert,
        :parameters => {},
        :body_object => body_data
    )

    raise StandardError.new(message:result.data["error"]["message"]) unless result.status == 200
    result.data
  end

  def delete_group_google(data)
  	client = get_google_client('https://www.googleapis.com/auth/admin.directory.group')
  	admin = client.discovered_api('admin', 'directory_v1')

	  result = client.execute(
        :api_method => admin.groups.insert,
        :parameters => {:groupKey => data[:groupKey]},
    )
    raise StandardError.new(message:result.data["error"]["message"]) unless result.status == 200
    result.data
  end

  def create_group_member_google(data)
  	client = get_google_client('https://www.googleapis.com/auth/admin.directory.group.member')
  	admin = client.discovered_api('admin', 'directory_v1')

  	body_data = {
	      "kind" => "admin#directory#member",
 	      "role" => "MEMBER",
        "email" => data[:email],
        "id" => "1",
        "type" => "USER"
    }

	  result = client.execute(
        :api_method => admin.members.insert,
        :parameters => {:groupKey => data[:groupKey]},
        :body_object => body_data
    )

    raise StandardError.new(message:result.data["error"]["message"]) unless result.status == 200
    result.data
  end

  def delete_group_member_google(data)
  	client = get_google_client('https://www.googleapis.com/auth/admin.directory.group.member')
  	admin = client.discovered_api('admin', 'directory_v1')

	  result = client.execute(
        :api_method => admin.members.delete,
        :parameters => {:groupKey => data[:groupKey], :memberKey => data[:memberKey]},
    )

    raise StandardError.new(message:result.data["error"]["message"]) unless result.status == 200
    result.data
  end

  def get_verify_txt_google(data)
    client = get_google_client('https://www.googleapis.com/auth/siteverification')
    siteverification = client.discovered_api('siteVerification')

    body_data = {
      "site" => {
        "identifier" => data[:domain],
        "type" => "INET_DOMAIN"
      },
      "verificationMethod" => "DNS_TXT"
    }

    result = client.execute(
        :api_method => siteverification.web_resource.get_token,
        :parameters => {},
        :body_object => body_data
    )

    raise StandardError.new(message:result.data["error"]["message"]) unless result.status == 200
    result.data["token"]
  end

  def insert_site_verify_google(data)
    client = get_google_client('https://www.googleapis.com/auth/siteverification')
    siteverification = client.discovered_api('siteVerification')

    body_data = {
       "owners" => [
         "rinat@reseller.exod.co.uk"
       ],
       "site" => {
         "identifier" => data[:domain],
         "type" => "INET_DOMAIN"
       }
    }

    result = client.execute(
        :api_method => siteverification.web_resource.insert,
        :parameters => {:verificationMethod => 'DNS_TXT'},
        :body_object => body_data
    )
    raise StandardError.new(message:result.data["error"]["message"]) unless result.status == 200
    result.data
  end

end