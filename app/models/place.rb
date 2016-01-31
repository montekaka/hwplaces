class Place	
	attr_accessor :id, :formatted_address, :location, :address_components
  
  def to_s
    "#{@id}"
  end

  def initialize(params={})
  	@id=params[:_id].nil? ? params[:id] : params[:_id].to_s
  	@formatted_address = params[:formatted_address]
  	@address_components = params[:address_components].nil? ? params[:address_components] : params[:address_components].map{|address_component| AddressComponent.new(address_component)}  	
  	#@location = params[:geometry].nil? ? params[:geometry] : Point.new(params[:geometry][:location])
  	@location = params[:geometry].nil? ? params[:geometry] : Point.new(params[:geometry])
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

	def self.get_address_components(sort=nil, skip=nil, limit=nil)
		query = [{:$unwind=>'$address_components'},{:$project=>{:_id=>1, :formatted_address=>1, :address_components=>1, "geometry.geolocation"=>1}}]
		query << {"$sort"=>sort} if sort
		query << {"$skip"=>skip} if skip && skip > 0
		query << {"$limit"=>limit} if limit && limit > 0

		places = collection.find().aggregate(query)		
	end

	def self.get_country_names
		query = [
							{:$unwind=>'$address_components'},
							{:$project=>{"address_components.types"=>1, 
								"address_components.long_name"=>1}},
							{:$match=>{'address_components.types'=>'country'}},
							{:$group=>{
								:_id=>{:long_name=>'$address_components.long_name'}
								}
							}
						]
		country_long_name = collection.find.aggregate(query)
		return country_long_name.to_a.map{|h| h[:_id]['long_name']}
	end

	def self.find_ids_by_country_code(country_code)
		query = [
			{:$match=>{
				'address_components.short_name'=>country_code,
				'address_components.types'=>'country'
				}
			},
			{
				:$project=>{:_id=>1}
			}
		]
		result = collection.find.aggregate(query).map{|doc| doc[:_id].to_s}
	end

	def self.create_indexes
		collection.indexes.create_one({"geometry.geolocation"=>Mongo::Index::GEO2DSPHERE})
	end

	def self.remove_indexes
		collection.indexes.drop_one("geometry.geolocation_2dsphere")
	end

	def self.near(point, max_meters=nil)
		if max_meters
			query =	{:$near=>{:$geometry=>point.to_hash, :$maxDistance=>max_meters}}
		else
			query =	{:$near=>{:$geometry=>point.to_hash}}
		end
		return collection.find("geometry.geolocation"=>query)
	end

	def near(max_meters=nil)
		near_places = self.class.near(self.location, max_meters)
		return self.class.to_places(near_places)
	end

end