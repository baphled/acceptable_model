require "spec_helper"

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

  protected

  def groups= groups
    @groups = groups.collect {|group| Group.new :name => group} unless groups.nil?
  end
end
describe "AcceptableModel::Enumerable" do
  before do
    AcceptableModel.define 'artist'
    artist_enum = [
      AcceptableModel::Artist.new(:name => 'Busta Rhymes', :aliases => ['Busta Bus']),
      AcceptableModel::Artist.new(:name => 'Jay-Z', :aliases => ['Jiggaman']),
    ]
    Artist.stub(:all).and_return artist_enum
  end

  it "enumerates all models" do
    AcceptableModel::Artist.all.should be_an AcceptableModel::Enumerable
  end
end
