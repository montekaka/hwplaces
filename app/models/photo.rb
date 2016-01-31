class Photo
	attr_accessor :id, :location
	attr_writer :contents
	def initialize(params={})
			@id=params[:_id].nil? ? params[:id] : params[:_id].to_s
			if params[:metadata]
				if params[:metadata][:location]
					@location = Point.new(params[:metadata][:location])	
				end
				if params[:metadata][:place]									
					@place = params[:metadata][:place]
				end
			end
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
		if @id.nil?
			return false
		else
			return true
		end
	end

	def save		
		if self.persisted?		
			#true
			id = BSON::ObjectId.from_string(self.id)
			doc = self.class.mongo_client.database.fs.find(:_id=>id).first
			doc[:metadata][:location] = @location.to_hash
			doc[:metadata][:place] = @place
			self.class.mongo_client.database.fs.find(:_id=>id).update_one(doc)		
		else
			#false
			if @contents
				gps=EXIFR::JPEG.new(@contents).gps			
				@location = Point.new(:lng=>gps.longitude, :lat=>gps.latitude)						
				description = {}
				description[:content_type] = 'image/jpeg'
				#description[:metadata][:place] = @place
				#description[:metadata][:location] = @location.to_hash				
				description[:metadata] = {
					:location=>@location.to_hash,
					:place=>@place
				}
				#description[:metadata] = {:location=>@location.to_hash}
				#description[:metadata] = {:place=>@place}
				@contents.rewind
				grid_file = Mongo::Grid::File.new(@contents.read, description)			
				@id = grid_file.id.to_s
				@location = location				
				r = self.class.mongo_client.database.fs.insert_one(grid_file)
			end	
		end		
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

	def find_nearest_place_id(max_distance)
		result=nil
		near_places = Place.near(self.location, max_distance)		
		if near_places
			nearest_place = near_places.limit(1).projection(_id:1)
			if nearest_place.count > 0
				result = nearest_place.first[:_id]
			end
		end
		return result
	end	

	def place
		#gette		
		if @place
			Place.find(@place)
		end
	end
	def place=(p)
		if p.class == Place
			@place = BSON::ObjectId.from_string(p.id.to_s)
		elsif p.class == String
			@place = BSON::ObjectId.from_string(p)
		else
			@place = p
		end		
	end

	def self.find_photos_for_place(place_id)
		pid = BSON::ObjectId.from_string(place_id)
		result = self.mongo_client.database.fs.find("metadata.place"=>pid)
		return result
	end
end