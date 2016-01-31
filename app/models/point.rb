class Point
	attr_accessor :longitude, :latitude
	def initialize(params={})
		if params[:geolocation]
			@longitude = params[:geolocation][:coordinates][0]
			@latitude = params[:geolocation][:coordinates][1]
		elsif params[:coordinates]
			@longitude = params[:coordinates][0]
			@latitude = params[:coordinates][1]
		elsif params[:location]
			@longitude = params[:location][:coordinates][0]
			@latitude = params[:location][:coordinates][1]			
		else
			@longitude = params[:lng]
			@latitude = params[:lat]
		end
	end
	def to_hash
		#{:longitude=>@longitude, :latitude=>@latitude}
		{:type=>"Point", :coordinates=>[@longitude,@latitude]}
	end		
end