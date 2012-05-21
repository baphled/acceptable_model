require "spec_helper"

describe AcceptableModel do
  let(:artist) { AcceptableModel::Artist.new :name => 'Busta Rhymes', :aliases => ['Busta Bus'] }
  let(:artists) { AcceptableModel::Artist.all } 
  let(:busta) { artists.first }
  let(:jayz) { artists.last }

  before :each do
    AcceptableModel.define 'artist'

    class AcceptableModel::Artist
      version ['json', 'xml', 'vnd.acme.artist-v1+json', 'vnd.acme.artist-v1+xml'] do |artist|
        { :id => artist.id, :name => artist.name }
      end
    end
  end

  describe "#mime_type_lookup" do
    context "passing the whole accepted header" do
      it "should be able to take the 'application/' prefix" do
        model = AcceptableModel::Artist.new :name => 'Busta Rhymes'
        expect {
          model.for('json')
        }.to_not raise_error Exception
      end
    end

    context "can work out basic mime types" do
      before do
        class AcceptableModel::Artist
          version ['application/json', 'application/xml'] do |artist|
            { :id => artist.id, :name => artist.name }
          end
        end
      end

      it "can handle json" do
        model = AcceptableModel::Artist.new :name => 'Busta Rhymes'
        model.mime_type_lookup('application/json').should eql 'json'
      end

      it "can handle xml" do
        model = AcceptableModel::Artist.new :name => 'Busta Rhymes'
        model.mime_type_lookup('application/xml').should eql 'xml'
      end

      it "can handle jsonp"
    end
  end

  describe "#attributes" do
    context "should not alter the original models attributes" do
      it "#to_json is called" do
        artist.for('vnd.acme.artist-v1+json')
        artist.attributes.should eql :id => 'busta-rhymes', :name => 'Busta Rhymes', :aliases => ['Busta Bus']
      end

      it "#to_xml is called" do
        artist.for('vnd.acme.artist-v1+xml')
        artist.attributes.should eql :id => 'busta-rhymes', :name => 'Busta Rhymes', :aliases => ['Busta Bus']
      end
    end
  end

	describe "#associations" do
		before :each do
			class AcceptableModel::Artist
				relationship :groups
			end
		end

		after do
			AcceptableModel.send :remove_const, :Artist
		end

		it "appends the associations" do
			model = AcceptableModel::Artist.new :name => 'Busta Rhymes'
			AcceptableModel::Artist.associations.should eql [ 'groups' ]
		end
	end

	describe "associations_by_version" do
		before :each do
			class AcceptableModel::Artist
				relationship :groups, :versions => ['application/json', 'text/xml']
			end
		end

		after do
			AcceptableModel.send :remove_const, :Artist
		end
		it "returns the associations for the given version" do
			model = AcceptableModel::Artist.new :name => 'Busta Rhymes'
			AcceptableModel::Artist.versioned_associations.should eql [ { 'groups' => {:versions => ['application/json', 'text/xml'] } } ]
		end
	end
  describe "#define" do
    it "dynamically defines a new class" do
      expect {
        AcceptableModel::Artist.new :name => 'Busta Rhymes'
      }.to_not raise_error Exception
    end

    it "can only define if the model is defined" do
      expect {
        AcceptableModel.define 'gopher'
      }.to raise_error AcceptableModel::ModelNotFound
    end

    it "exposes the originating models accessors" do
      model = AcceptableModel::Artist.new :name => 'Busta Rhymes'
      model.name.should eql 'Busta Rhymes'
    end
  end

  describe "#all" do
    let(:artists) { AcceptableModel::Artist.all } 
    let(:busta) { artists.first }
    let(:jayz) { artists.last }

    before do
      artist_enum = [
        Artist.new(:name => 'Busta Rhymes', :aliases => ['Busta Bus']),
        Artist.new(:name => 'Jay-Z', :aliases => ['Jiggaman']),
      ]
      Artist.stub(:all).and_return artist_enum
    end

    it "is returning JSON" do
      artists.for('vnd.acme.artist-v1+json')
      busta.attributes.should eql :id => 'busta-rhymes', :name => 'Busta Rhymes', :aliases => ['Busta Bus']
      jayz.attributes.should eql :id => 'jay-z', :name => 'Jay-Z', :aliases => ['Jiggaman']
    end

    it "is returning XML" do
      artists.for('vnd.acme.artist-v1+xml')
      busta.attributes.should eql :id => 'busta-rhymes', :name => 'Busta Rhymes', :aliases => ['Busta Bus']
      jayz.attributes.should eql :id => 'jay-z', :name => 'Jay-Z', :aliases => ['Jiggaman']
    end
  end

  describe "#for" do
    it "returns at HATEOAS like format" do
      expected = { :artist => {
          :id => 'busta-rhymes',
          :name => 'Busta Rhymes',
          :links => [
            {
              :href => '/artists/busta-rhymes',
              :rel => '/self'
            }
          ]
        }
      }
      model = AcceptableModel::Artist.new :name => 'Busta Rhymes'
      model.for('vnd.acme.artist-v1+json').should eql expected.to_json
    end

    it "should handle any extra information passed via the header" do
      model = AcceptableModel::Artist.new :name => 'Busta Rhymes'
      expect {
        model.for('xml')
      }.to_not raise_error Exception
    end

    context "extended relationships" do
      let(:relationships) {
        { :artist =>
          {
            :id => 'busta-rhymes',
            :name => 'Busta Rhymes',
            :groups => [
              {
                'id' => 'flipmode-squad',
                'name' => 'Flipmode Squad',
                'links' => [
                  {
                   'href' => '/groups/flipmode-squad',
                   'rel' => '/children'
                  }
                ]
              },
              {
                'id' => 'leaders-of-the-new-school',
                'name' => 'Leaders of The New School',
                'links' => [
                  {
                   'href' => '/groups/leaders-of-the-new-school',
                   'rel' => '/children'
                  }
                ]
              }
            ],
            :links => [
              {
                :href => '/artists/busta-rhymes',
                :rel => '/self'
              },
              {
                :href => '/groups/flipmode-squad',
                :rel => '/partOf'
              },
              {
                :href => '/groups/leaders-of-the-new-school',
                :rel => '/partOf'
              }
            ]
          }
        }
      }

      let(:expected_xml) { File.read('spec/fixtures/artist_with_groups.xml') }
      let( :model ) { 
        params = {
          :name => 'Busta Rhymes',
          :groups => ['Flipmode Squad', 'Leaders of The New School']
        }
        AcceptableModel::Artist.new params
      }
      let(:group1) { Group.new :name => 'Flipmode Squad', :id => 'flipmode-squad' }
      let(:group2) { Group.new :name => 'Leaders of The New School', :id => 'leaders-of-the-new-school' }

      before :each do
        class AcceptableModel::Artist
          version ['vnd.acme.artist-v1+json', 'vnd.acme.artist-v1+xml'] do |artist|
            {
              :id => artist.id,
              :name => artist.name
            }
          end

          relationship :groups

          def part_of
            groups.all
          end
        end
        model.groups.stub(:all).and_return [group1, group2]
      end

      after :each do
        AcceptableModel.send :remove_const, :Artist
      end

      it "allows for the output format to be passed" do
        model.for('vnd.acme.artist-v1+json').should eql relationships.to_json
      end

      it "can deal with XML formats the same as JSON formats" do
        model.for('vnd.acme.artist-v1+xml').should eql expected_xml
      end

      it "mime type not found" do
        expect {
          model.for('vnd.acme.artist-v1+foo')
        }.to raise_error AcceptableModel::MimeTypeNotReckonised
      end
    end
  end
end
