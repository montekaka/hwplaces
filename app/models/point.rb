class Point
	attr_accessor :longitude, :latitude
	def initialize(params={})
		if params[:geolocation]
			@longitude = params[:geolocation][:coordinates][0]
			@latitude = params[:geolocation][:coordinates][1]
		else
			@longitude = params[:location][:lng]
			@latitude = params[:location][:lat]
		end
	end
	def to_hash
		#{:longitude=>@longitude, :latitude=>@latitude}
		{:type=>"Point", :coordinates=>[@longitude,@latitude]}
	end		
end