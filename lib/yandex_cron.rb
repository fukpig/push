require '/home/api-ps/lib/yandex'

loop do
  begin
  	pdd = Yandex::PDD::new
  	crons = YandexCron.all
  	crons.each do |cron|
      password = Array.new(10){[*"A".."Z", *"0".."9"].sample}.join
    	result = pdd.email_create(cron['domain'], cron['email'], password)
   	  if result["success"] == "ok"
         cron.destroy! 
         puts "#{cron['email']}@#{cron['domain']} succefully created"
      else 
        puts "#{cron['email']}@#{cron['domain']} not yet delegated"
      end
  	end
  rescue => e
  	puts e.message
  ensure
  	sleep(15)
  end	
end