require "spec_helper"

describe AcceptableModel::DSL do
  describe "#define" do
    context "defined model" do
      before :each do
        AcceptableModel.define 'artist'
      end

      after do
        AcceptableModel.send :remove_const, :Artist
      end

      it "dynamically defines a new class" do
        expect {
          AcceptableModel::Artist.new :name => 'Busta Rhymes'
        }.to_not raise_error Exception
      end

      it "exposes the originating models accessors" do
        model = AcceptableModel::Artist.new :name => 'Busta Rhymes'
        model.name.should eql 'Busta Rhymes'
      end
    end

    it "can only define if the model is defined" do
      expect {
        AcceptableModel.define 'gopher'
      }.to raise_error AcceptableModel::ModelNotFound
    end
  end

  describe "#mime_types" do
    before :each do
      AcceptableModel.define 'artist'
    end

    after do
      AcceptableModel.send :remove_const, :Artist
    end

    it "should allow me to define a versioned response" do
      expect {
        class AcceptableModel::Artist
          mime_types ['json'] do |artist|
            { :id => artist.id, :name => artist.name }
          end
        end
      }.to_not raise_error NoMethodError
    end

    it "deprecates #version" do
      Kernel.should_receive :warn
      class AcceptableModel::Artist
        version ['vnd.acme.artist-v3+xml'] do |artist|
          { :name => artist.name }
        end
      end
    end
  end
end
