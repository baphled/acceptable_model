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
          mime_types ['vnd.acme.artist-v3+xml'] do |artist|
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

  describe "#relationship" do
    after do
      AcceptableModel.send :remove_const, :Artist
    end

    it "handles response relationships" do
      AcceptableModel.define 'artist'
      expect {
        class AcceptableModel::Artist
          relationship :groups
        end
      }.to_not raise_error NoMethodError
    end
  end

  describe "#associations" do

    context "basic relationships" do
      before :each do
        AcceptableModel.define 'artist'

        class AcceptableModel::Artist
          mime_types ['json', 'xml', 'vnd.acme.artist-v1+json', 'vnd.acme.artist-v1+xml'] do |artist|
            { :id => artist.id, :name => artist.name }
          end

          relationship :groups
        end
      end

      after do
        AcceptableModel.send :remove_const, :Artist
      end

      it "get a list of custom mime types" do
        expected = ['groups']
        AcceptableModel::Artist.associations.should eql expected
      end
    end

    context "versioned relationships" do
      before :each do
        AcceptableModel.define 'artist'

        class AcceptableModel::Artist
          mime_types ['json', 'xml', 'vnd.acme.artist-v1+json', 'vnd.acme.artist-v1+xml'] do |artist|
            { :id => artist.id, :name => artist.name }
          end
          relationship :singles, :version => ['xml']
        end
      end

      it "only finds associations that match the given mime type" do
        AcceptableModel::Artist.associations('json').should eql []
        AcceptableModel::Artist.associations.should eql ['singles']
      end
    end
  end
end
