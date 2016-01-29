class Place	
	attr_accessor :id, :formatted_address, :location, :address_components
  
  def to_s
    "#{@id}"
  end

  def initialize(params={})
  	@id=params[:_id].nil? ? params[:id] : params[:_id].to_s
  	@formatted_address = params[:formatted_address]
  	@address_components = params[:address_components].nil? ? params[:address_components] : params[:address_components].map{|address_component| AddressComponent.new(address_component)}
  	#@address_components = params[:address_components].map {|a| AddressComponent.new(a)}
  	@location = params[:geometry].nil? ? params[:geometry] : Point.new(params[:geometry][:location])
  end

	def self.mongo_client
		Mongoid::Clients.default
	end
	def self.collection
		self.mongo_client['places']
	end
	def self.load_all(param)
		file = param.read
		hash = JSON.parse(file)
		entries = self.collection
		entries.insert_many(hash)
	end
	def self.find_by_short_name(short_name)
		collection.find({'address_components.short_name'=> short_name})
	end

	def self.to_places(params)
		places = []
		params.each do |p|
			places << Place.new(p)
		end
		return places
	end	

	def self.find(id)
		place_id = BSON::ObjectId.from_string(id)		
		place = collection.find(:_id=> place_id).first

		if place
			return Place.new(place)	
		end
	end

	def self.all(offset=0, limit=nil)
		tmp = {} #hash needs to stay in stable order provided
		places = collection.find.skip(offset)
		places = places.limit(limit) if !limit.nil?
		result = []
		places.each do |p|
			result << Place.new(p)
		end
		return result
	end

	def destroy
		self.class.collection
							.find(_id:BSON::ObjectId.from_string(@id.to_s))
							.delete_one
	end
end