require "spec_helper"

describe AcceptableModel::RelationshipsMapper do
  let( :artist ) { 
    params = {
      :name => 'Busta Rhymes',
      :groups => ['Flipmode Squad', 'Leaders of The New School']
    }
    AcceptableModel::Artist.new params
  }
  let(:group1) { Group.new :name => 'Flipmode Squad', :id => 'flipmode-squad' }
  let(:group2) { Group.new :name => 'Leaders of The New School', :id => 'leaders-of-the-new-school' }
  let(:structure) {
    Proc.new do |model, relationship|
      {
        :href => "/#{model.class.to_s.downcase.pluralize}/#{model.id}",
        :rel => "/#{relationship.camelize :lower}"
      }
    end
  }
  let(:associations) { AcceptableModel::Artist.associations }
  let(:attributes) { artist.version_lookup( 'vnd.acme.artist-v1+json')[:attributes] }
  let( :mapper ) { AcceptableModel::RelationshipsMapper.new :model => artist, :response_block => structure, :attributes_block => attributes, :associations => associations }

  before :each do
    AcceptableModel.define 'artist'
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
    artist.groups.stub(:all).and_return [group1, group2]
  end

  after do
    AcceptableModel.send :remove_const, :Artist
  end

  it "takes a model" do
    expect {
      AcceptableModel::RelationshipsMapper.new :model => artist, :response_block => structure, :attributes_block => attributes, :associations => associations
    }.to_not raise_error Exception
  end

  it "exposes the model" do
    mapper.model.should_not be_nil
  end

  it "knows what attributes should be returned" do
    mapper.attributes.should_not include :groups=>["Flipmode Squad", "Leaders of The New School"]
  end

  describe "#response_block" do
    it "takes a structure block" do
      expected =
      {
        :href => '/artists/123',
        :rel => '/children'
      }
      mapper.response_block.call( stub(:class => Artist, :id => '123'), 'children' ).should eql expected
    end
  end

  describe "#associations" do
    it "can take the a list of model associations" do
      mapper.associations.should be_an Array
    end
  end

  describe "#links" do
    it "creates the hash for the links" do
      links = [
        {:href=>"/artists/busta-rhymes", :rel=>"/self"},
        {:href=>"/groups/flipmode-squad", :rel=>"/partOf"},
        {:href=>"/groups/leaders-of-the-new-school", :rel=>"/partOf"}
      ]
      mapper.links.should eql links
    end

  end

  describe "#relationships" do
    it "creates the hash for the associations" do
      expected = [
        {
          :groups => [
            {
              :id => 'flipmode-squad',
              :name => 'Flipmode Squad',
              :links => [
                {
                  :href => '/groups/flipmode-squad',
                  :rel => '/children'
                }
              ]
            },
            {
              :id => 'leaders-of-the-new-school',
              :name => 'Leaders of The New School',
              :links => [
                {
                  :href => '/groups/leaders-of-the-new-school',
                  :rel => '/children'
                }
              ]
            }
          ]
        }
      ]
      mapper.relationships.should eql expected
    end
  end

  describe "#representation" do
    it "includes the models attributes" do
      expected = {:id=>"busta-rhymes", :name=>"Busta Rhymes"}
      mapper.representation.should include expected
    end

    it "includes the models associations" do
      links = {
        :links => [
          {:href=>"/artists/busta-rhymes", :rel=>"/self"},
          {:href=>"/groups/flipmode-squad", :rel=>"/partOf"},
          {:href=>"/groups/leaders-of-the-new-school", :rel=>"/partOf"}
        ]
      }
      mapper.representation.should include links
    end

    it "includes the models relationships" do
      expected = {
          :groups => [
            {
              :id => 'flipmode-squad',
              :name => 'Flipmode Squad',
              :links => [
                {
                  :href => '/groups/flipmode-squad',
                  :rel => '/children'
                }
              ]
            },
            {
              :id => 'leaders-of-the-new-school',
              :name => 'Leaders of The New School',
              :links => [
                {
                  :href => '/groups/leaders-of-the-new-school',
                  :rel => '/children'
                }
              ]
            }
          ]
        }

      mapper.representation.should include expected
    end

    it "should not include attributes we don't care about" do
      mapper.attributes.should_not include :groups => ["Flipmode Squad", "Leaders of The New School"]
    end
  end
end
