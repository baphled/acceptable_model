require "spec_helper"

describe AcceptableModel::HATEOAS do
  it "should have a list of relationship types" do
    AcceptableModel::HATEOAS.relationship_types.should eql %w{part_of parent child contains prev next same_as}
  end

  describe "#config" do
    it "allows us to add our own rel types" do
      AcceptableModel::HATEOAS.config do |config|
        config.relationships = %w{service}
      end
      AcceptableModel::HATEOAS.relationship_types.should include 'service'
    end
  end

  describe "#relationship" do
    let(:model) { AcceptableModel::Artist.new :name => 'Busta Rhymes', :aliases => ['Busta Bus'], :groups => ['Flipmode Squad', 'Leaders of The New School'] }
    let(:group1) { Group.new :name => 'Flipmode Squad', :id => 'flipmode-squad' }
    let(:group2) { Group.new :name => 'Leaders of The New School', :id => 'leaders-of-the-new-school' }

    before do
      AcceptableModel.define 'artist'
      class AcceptableModel::Artist
        version ['vnd.acme.artist-v1+json', 'vnd.acme.artist-v1+xml'] do |artist|
          {
            :id => artist.id,
            :name => artist.name
          }
        end

        relationship :groups, :version => ['vnd.acme.artist-v1+json',  'vnd.acme.artist-v1+xml']
        def part_of
          groups.all
        end
      end
      model.groups.stub(:all).and_return [group1, group2]
    end

    after do
      AcceptableModel.send :remove_const, :Artist
    end

    it "lists the objects relationships" do
      AcceptableModel::Artist.associations.should include 'groups'
    end

    it "should have a list of associations" do
      AcceptableModel::Artist.associations.should be_a Array
    end

    it "should allow use to define a relationship" do
      expected = 
        { 'artist' =>
          {
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
            'links' => [
              {
                'href' => '/artists/busta-rhymes',
                'rel' => '/self'
              },
              {
                'href' => '/groups/flipmode-squad',
                'rel' => '/partOf'
              },
              {
                'href' => '/groups/leaders-of-the-new-school',
                'rel' => '/partOf'
              }
            ]
          }
        }
      model.for('vnd.acme.artist-v1+json').should eql expected.to_json
    end

    it "outputs links with the href and rel as an attribute" do
      expected = File.open('spec/fixtures/artist_with_groups.xml').read
      model.for('vnd.acme.artist-v1+xml').should eql expected
    end
  end
end
