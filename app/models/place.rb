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
  	@location = params[:geometry].nil? ? params[:geometry] : Place.new(params[:geometry][:location])
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
end