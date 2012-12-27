Given /^there is a artist with a name$/ do
class Artist
  include Mongoid::Document
  include Mongoid::Slug

  field :name
  slug :name

end

  Artist.create :name => 'Busta Rhymes'
end

Given /^the "(.*?)" is defined as an AcceptableModel$/ do |model|
  AcceptableModel.define model
end

Given /^there is an artist associated to a group$/ do
  class Group
    include Mongoid::Document
    include Mongoid::Slug

    field :name
    slug :name

  end

  class Artist
    include Mongoid::Document
    include Mongoid::Slug

    field :name
    slug :name

    has_and_belongs_to_many :groups
  end

  group = Group.create :name => 'Leaders of the new skool'
  a = Artist.create :name => 'Busta Rhymes', :groups => [group]
end

When /^I create the following custom mime types$/ do |mime_type_definition|
  eval mime_type_definition
end

When /^a service for "(.*?)" has been created$/ do |resource|
  class ExampleApi < Sinatra::Base
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
      artist = AcceptableModel::Artist.find params[:id]
      artist.for respond_to
    end

    get '/artists' do
      artists = AcceptableModel::Artist.all
      artists.for respond_to
    end
  end
  Capybara.app = ExampleApi
end

Then /^the presenters model id should be "(.*?)"$/ do |attribute|
  AcceptableModel::Artist.first.attributes[:id].should eql attribute
end

When /^I make a request for the "(.*?)" resource "(.*?)" with "(.*?)"$/ do |resource, id, accept_header|
  Capybara.current_session.driver.header 'Accept', accept_header
  visit "http://example.com/#{resource}/#{id}"
end

Then /^I should see$/ do |string|
  JSON.parse(page.body).should eql JSON.parse string
end
