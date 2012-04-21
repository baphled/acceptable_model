class AcceptableModel
  def self.define model
    dynamic_name = "Acceptable#{model.capitalize}"
    Object.const_set(dynamic_name, Class.new)
  end
end
describe AcceptableModel do
  describe "#define" do
    it "dyanmically defines a new class" do
      AcceptableModel.define :artist
      expect {
        AcceptableArtist.new
      }.to_not raise_error Exception
    end
  end
end
