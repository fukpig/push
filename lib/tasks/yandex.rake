namespace :yandex do
  desc "Rake task to get events data"
  task :cron => :environment do
    	require 'yandex'
      pdd = Yandex::PDD::new
    	crons = YandexCron.all
    	crons.each do |cron|
        begin
          password = Array.new(10){[*"A".."Z", *"0".."9"].sample}.join
        	result = pdd.email_create(cron['domain'], cron['email'], password)
       	  if result["success"] == "ok"
             cron.destroy! 
             puts "#{cron['email']}@#{cron['domain']} succefully created"
          end
        rescue => e
          puts "#{cron['email']}@#{cron['domain']} not yet delegated"
          next
        end
    	end

	
	puts "#{Time.now} - Success!"
  end
end