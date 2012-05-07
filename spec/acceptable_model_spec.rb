require "spec_helper"

describe AcceptableModel do
  before :each do
    AcceptableModel.define 'artist'
  end

  it "should have a list of rel types" do
    AcceptableModel::HATEOS.relationship_types.should eql %w{part_of parent child contains prev next same_as}
  end
  
  it "allows us to add our own rel types" do
    AcceptableModel::HATEOS.config do |config|
      config.relationships = %w{service}
    end
    AcceptableModel::HATEOS.relationship_types.should include 'service'
  end

  describe "#attributes" do
    context "should not alter the original models attributes" do
      let(:artist) { AcceptableModel::Artist.new :name => 'Busta Rhymes', :aliases => ['Busta Bus'] }
      let(:artists) { AcceptableModel::Artist.all } 
      let(:busta) { artists.first }
      let(:jayz) { artists.last }

      before do
        class AcceptableModel::Artist
          version ['vnd.acme.artist-v1+json', 'vnd.acme.artist-v1+xml'] do |artist|
            {
              :id => artist.id,
              :name => artist.name
            }
          end
        end
      end

      context "returning single models" do
        it "is returning JSON" do
          artist.to_json
          artist.attributes.should eql :id => 'busta-rhymes', :name => 'Busta Rhymes', :aliases => ['Busta Bus']
        end

        it "is returning XML" do
          artist.to_xml
          artist.attributes.should eql :id => 'busta-rhymes', :name => 'Busta Rhymes', :aliases => ['Busta Bus']
        end
      end

      context "returning all" do
        before do
          artist_enum = AcceptableModel::Enumerable.new [
            AcceptableModel::Artist.new(:name => 'Busta Rhymes', :aliases => ['Busta Bus']),
            AcceptableModel::Artist.new(:name => 'Jay-Z', :aliases => ['Jiggaman']),
          ]
          AcceptableModel::Artist.stub(:all).and_return artist_enum
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
    end
  end

  describe "#define" do
    it "dyanmically defines a new class" do
      expect {
        AcceptableModel::Artist.new :name => 'Busta Rhymes'
      }.to_not raise_error Exception
    end
  end

  context "a dynamically defined class" do
    it "exposes the originating models accessors" do
      model = AcceptableModel::Artist.new :name => 'Busta Rhymes'
      model.name.should eql 'Busta Rhymes'
    end
  end

  context "define associative relationships" do
    before do
      class AcceptableModel::Artist
        relationship :group
      end
    end

    it "lists the objects relationships" do
      AcceptableModel::Artist.associations.should include 'group'
    end

    it "should have a list of associations" do
      AcceptableModel::Artist.associations.should be_a Array
    end

    it "should allow use to define a relationship" do
      expected = {
        'id' => 'busta-rhymes',
        'name' => 'Busta Rhymes',
        'groups' => [
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
          }
        ]
      }.to_json
      model = AcceptableModel::Artist.new :name => 'Busta Rhymes', :groups => ['Flipmode Squad', 'Leaders of The New School']
      model.to_json.should eql expected
    end
  end

  describe "#to_json" do
    it "returns at HATEOS like format" do
      expected = {
        :id => 'busta-rhymes',
        :name => 'Busta Rhymes',
        :links => [
          {
            :href => '/artists/busta-rhymes',
            :rel => '/self'
          }
        ]
      }.to_json
      model = AcceptableModel::Artist.new :name => 'Busta Rhymes'
      model.to_json.should eql expected
    end

    context "extended relationships" do
      let(:relationships) {
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

      let(:expected_xml) {
'''<?xml version="1.0" encoding="UTF-8"?>
<artist>
  <id>busta-rhymes</id>
  <name>Busta Rhymes</name>
  <groups>
    <group>
      <id>flipmode-squad</id>
      <name>Flipmode Squad</name>
      <links>
        <link>
          <href>/groups/flipmode-squad</href>
          <rel>/children</rel>
        </link>
      </links>
    </group>
    <group>
      <id>leaders-of-the-new-school</id>
      <name>Leaders of The New School</name>
      <links>
        <link>
          <href>/groups/leaders-of-the-new-school</href>
          <rel>/children</rel>
        </link>
      </links>
    </group>
  </groups>
  <links>
    <link>
      <href>/artists/busta-rhymes</href>
      <rel>/self</rel>
    </link>
    <link>
      <href>/groups/flipmode-squad</href>
      <rel>/partOf</rel>
    </link>
    <link>
      <href>/groups/leaders-of-the-new-school</href>
      <rel>/partOf</rel>
    </link>
  </links>
</artist>
'''
      }
      let( :model ) { AcceptableModel::Artist.new :name => 'Busta Rhymes', :groups => ['Flipmode Squad', 'Leaders of The New School'] }
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

          def part_of
            groups.all
          end
        end
        model.groups.stub(:all).and_return [group1, group2]
      end

      after do
        class AcceptableModel::Artist
          undef part_of
        end
      end

      it "can extend the relationship links" do
        model.to_json.should eql relationships.to_json
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
    describe "#all" do
      let(:relationships) {
        [
          {
            :id => 'busta-rhymes',
            :name => 'Busta Rhymes',
            :links => [
              {
                :href => '/artists/busta-rhymes',
                :rel => '/self'
              }
            ]
          },
          {
            :id => 'jay-z',
            :name => 'Jay-Z',
            :links => [
              {
                :href => '/artists/jay-z',
                :rel => '/self'
              }
            ]
          },
        ]
      }
      before :each do
        class AcceptableModel::Artist
          version ['vnd.acme.artist-v1+json','vnd.acme.artist-v1+xml'] do |artist|
            {
              :id => artist.id,
              :name => artist.name
            }
          end
        end

        artist_enum = AcceptableModel::Enumerable.new [
          AcceptableModel::Artist.new(:name => 'Busta Rhymes', :aliases => ['Busta Bus']),
          AcceptableModel::Artist.new(:name => 'Jay-Z', :aliases => ['Jiggaman']),
        ]
        AcceptableModel::Artist.stub(:all).and_return artist_enum
      end

      it "should be able to handle an array of objects that AcceptableModel knows about" do
        artists = AcceptableModel::Artist.all
        artists.for('vnd.acme.artist-v1+json').should eql relationships.to_json
      end

      it "should support XML also" do
        expected = 
'''<?xml version="1.0" encoding="UTF-8"?>
<artists>
  <artist>
    <id>busta-rhymes</id>
    <name>Busta Rhymes</name>
    <links>
      <link>
        <href>/artists/busta-rhymes</href>
        <rel>/self</rel>
      </link>
    </links>
  </artist>
  <artist>
    <id>jay-z</id>
    <name>Jay-Z</name>
    <links>
      <link>
        <href>/artists/jay-z</href>
        <rel>/self</rel>
      </link>
    </links>
  </artist>
</artists>
'''
        artists = AcceptableModel::Artist.all
        artists.for('vnd.acme.artist-v1+xml').should eql expected
      end
    end
  end
end
