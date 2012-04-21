require "acceptable_model"

class Artist
  attr_accessor :name

  def initialize params = {}
    self.name = params[:name]
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
end
