require '/home/api-ps/lib/google'

loop do
  begin
    google = GOOGLE.new()
  	data = {:domain => 'pushtostart.ru'}
 	google.insert_site_verify_google(data)
  rescue => e
  	puts e.message
  ensure
  	sleep(15)
  end	
end