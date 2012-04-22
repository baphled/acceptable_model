require "acceptable_model"

require "json"

class Artist
  attr_accessor :name, :id
  include AcceptableModel::HateOS

  def initialize params = {}
    self.name = params[:name]
    self.id = self.name.downcase.gsub(' ', '-')
  end

  def to_json
    super :name => name
  end
end


describe AcceptableModel do
  before :all do
    AcceptableModel.define 'artist'
  end

  describe "#define" do
    it "dyanmically defines a new class" do
      expect {
        AcceptableArtist.new :name => 'Busta Rhymes'
      }.to_not raise_error Exception
    end
  end

  context "a dynamically defined class" do
    it "exposes the originating models accessors" do
      model = AcceptableArtist.new :name => 'Busta Rhymes'
      model.name.should eql 'Busta Rhymes'
    end
  end

  describe "#to_json" do
    it "returns at HATEOS like format" do
      expected = {
        :links => [
          {
            :href => '/artists/busta-rhymes',
            :rel => '/self'
          }
        ],
        :name => 'Busta Rhymes'
      }.to_json
      model = AcceptableArtist.new :name => 'Busta Rhymes'
      model.to_json.should eql expected
    end
  end
end
