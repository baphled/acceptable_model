require "active_support/inflector"
require "delegate"

class Artist
  attr_accessor :name

  def initialize params = {}
    self.name = params[:name]
  end
end

class AcceptableModel

  def self.define model
    dynamic_name = "Acceptable#{model.capitalize}"
    model_object = model.capitalize.constantize
    Object.const_set(dynamic_name, model_object)
  end
end
describe AcceptableModel do
  describe "#define" do
    it "dyanmically defines a new class" do
      AcceptableModel.define 'artist'
      expect {
        AcceptableArtist.new :name => 'Busta Rhymes'
      }.to_not raise_error Exception
    end

    it "exposes the originating models accessors" do
      AcceptableModel.define 'artist'
      model = AcceptableArtist.new :name => 'Busta Rhymes'
      model.name.should eql 'Busta Rhymes'
    end
  end
end
