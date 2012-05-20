require "acceptable_model"
require "sinatra"
require "rack/accept"

class Artist
  attr_accessor :name, :aliases, :id, :groups
  attr_accessor :attributes

  def initialize params = {}
    self.name = params[:name]
    self.aliases = params[:aliases]
    self.id = self.name.downcase.gsub(' ', '-')
    self.attributes = { :id => self.id }
    self.attributes.merge! params
  end

  def self.find params = {}
    new( :name => 'Busta Rhymes', :aliases => 'Busta Bus' )
  end

  def self.all
    [ new( :name => 'Busta Rhymes', :aliases => 'Busta Bus' ) ]
  end
end

AcceptableModel.define 'artist'

class AcceptableModel::Artist
  version ['application/json', 'text/xml', 'application/vnd.acme.artist-v1+json', 'application/vnd.acme.artist-v1+xml'] do |artist|
    { :id => artist.id, :name => artist.name }
  end

  version ['application/vnd.acme.artist-v2+json', 'application/vnd.acme.artist-v2+xml'] do |artist|
    {:id => artist.id, :name => artist.name, :aliases => artist.aliases}
  end
end

class Example < Sinatra::Base

  configure do
    AcceptableModel::Artist.version_mapper.each { |mime| mime_type mime[:version] }
  end

  def respond_to
    mimes = Rack::Accept::MediaType.new request.env['HTTP_ACCEPT']
    accepted = AcceptableModel::Artist.version_mapper.collect { |mime| mime[:version] }
    response = mimes.best_of(accepted)
    content_type response
    response
  end

  get '/artists/:id' do
    artist = AcceptableModel::Artist.find :id => params[:id]
    artist.for respond_to
  end
end
