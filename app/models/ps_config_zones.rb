class PsConfigZones < ActiveRecord::Base

	def self.get_zone(name)
	  zone = PsConfigZones.where("name = ?", name).first
			
	  if zone.nil?
		raise ApiError.new("Find zone failed", "FIND_ZONE_FAILED", 'Not such zone')
	  end
	  return zone
	end
end
