require "acceptable_model"
require "sinatra"
require "rack/accept"

class Artist
  attr_accessor :name, :aliases, :id, :groups
  attr_accessor :attributes

  def initialize params = {}
    self.name = params[:name]
    self.aliases = params[:aliases]
    self.groups = params[:groups]
    self.id = self.name.downcase.gsub(' ', '-')
    self.attributes = { :id => self.id }
    self.attributes.merge! params
  end

  def self.find params = {}
    new( :name => 'Busta Rhymes', :aliases => 'Busta Bus', :groups => ['Flipmode Squad', 'Leaders of The New School'] )
      
  end

  def self.all
    [ find( :id => 'busta-rhymes' ) ]
  end

  def groups
    group1 = Group.new :name => 'Flipmode Squad', :id => 'flipmode-squad'
    group2 = Group.new :name => 'Leaders of The New School', :id => 'leaders-of-the-new-school'
    [group1, group2]
  end

  protected

  def groups= groups
    @groups = groups.collect {|group| Group.new :name => group} unless groups.nil?
  end
end

class Group
  attr_accessor :name, :id
  attr_accessor :attributes

  def initialize params = {}
    self.name = params[:name]
    self.id = self.name.downcase.gsub(' ', '-')
    self.attributes = { :id => self.id }
    self.attributes.merge! params
  end

  def attributes
    @attributes ||= {:id => id, :name => name}
  end
end

AcceptableModel.define 'artist'

class AcceptableModel::Artist
  mime_types ['application/json', 'text/xml', 'application/vnd.acme.artist-v1+json', 'application/vnd.acme.artist-v1+xml'] do |artist|
    { :id => artist.id, :name => artist.name }
  end

  mime_types ['application/vnd.acme.artist-v2+json', 'application/vnd.acme.artist-v2+xml'] do |artist|
    {:id => artist.id, :name => artist.name, :aliases => artist.aliases}
  end

  relationship :groups, :version => ['application/vnd.acme.artist-v2+json']
end

class Example < Sinatra::Base

  configure do
    AcceptableModel::Artist.version_mapper.each { |mime| mime_type mime[:version] }
  end

  #
  # This could be handle by AcceptableApi
  #
  # Instead of having to use AcceptableModel in the controller we could call
  # the normal model and let AcceptableApi delegate to AcceptableModel
  #
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

  get '/artists' do
    artists = AcceptableModel::Artist.all
    artists.for respond_to
  end
end
