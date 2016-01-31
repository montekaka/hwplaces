class Photo
	attr_accessor :id, :location
	attr_writer :contents
	def initialize(params={})
		@id=params[:_id].nil? ? params[:id] : params[:_id].to_s
		@location = params[:metadata].nil? ? params[:metadata] : Point.new(params[:metadata])		
	end	
	def self.mongo_client
		Mongoid::Clients.default
	end		
	def contents
		id = BSON::ObjectId(self.id)
		p = self.class.mongo_client.database.fs.find_one(:_id=>id)
		# if p
		# 	return p[:length]
		# end
		if p
			buffer = ""
			p.chunks.reduce([]) do |x,chunk| 
				buffer << chunk.data.data 
			end
			return buffer
		end
		
	end	
	def persisted?
		if self.id.nil?
			return false
		else
			return true
		end
	end

	def save
		if self.persisted?
		end
		if @contents
			gps=EXIFR::JPEG.new(@contents).gps			
			location = Point.new(:lng=>gps.longitude, :lat=>gps.latitude)		
			description = {}
			description[:content_type] = 'image/jpeg'
			description[:metadata] = {:location=>location.to_hash}					
			@contents.rewind
			grid_file = Mongo::Grid::File.new(@contents.read, description)			
			@id = grid_file.id.to_s
			@location = location
			r = self.class.mongo_client.database.fs.insert_one(grid_file)
		end
		#return @id
	end

	def self.all(offset=0, limit=nil)		
		photos = mongo_client.database.fs.find.skip(offset)
		photos = photos.limit(limit) if !limit.nil?	
		#result = photos.each {|p| Photo.new(p)}
		result = []
		photos.each do |p|
			result << Photo.new(p)
		end
		return result		
	end

	def self.find(p_id)
		id = BSON::ObjectId.from_string(p_id)
		p = mongo_client.database.fs.find(:_id=>id).first
		if p
			photo = Photo.new(p)
			#photo.location = p[:metadata][:location]	
			return photo
		end
	end

	def destroy
		id = BSON::ObjectId(self.id)
		if self.class.mongo_client.database.fs.find(:_id=>id)
			self.class.mongo_client.database.fs.find(:_id=>id).delete_one
		end
	end

	def find_nearest_place_id(max_distance=nil)
		result=nil
		near_places = Place.near(self.location, max_distance)
		nearest_place = near_places.limit(1).projection(_id:1)
		if nearest_place
			result = nearest_place.first[:_id]
			return result
		end
	end	
end