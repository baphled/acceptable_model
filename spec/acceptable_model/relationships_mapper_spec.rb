require "spec_helper"

describe AcceptableModel::RelationshipsMapper do
  let(:model) { AcceptableModel::Artist.new :name => 'Busta Rhymes', :aliases => ['Busta Bus'] }
  let(:group1) { Group.new :name => 'Flipmode Squad', :id => 'flipmode-squad' }
  let(:group2) { Group.new :name => 'Leaders of The New School', :id => 'leaders-of-the-new-school' }

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
    model.groups.stub(:all).and_return [group1, group2]
  end

  it "takes a model" do
    expect {
      AcceptableModel::RelationshipsMapper.new :model => model
    }.to_not raise_error Exception
  end

  it "exposes the model" do
    mapper = AcceptableModel::RelationshipsMapper.new :model => model
    mapper.model.should be_a AcceptableModel::Artist
  end

  describe "#response_block" do
    let(:structure) {
      Proc.new do |model, relationship|
        {
          :href => "/#{model.class.to_s.downcase.pluralize}/#{model.id}",
          :rel => "/#{relationship.camelize :lower}"
        }
      end
    }

    it "takes a structure block" do
      expected =
      {
        :href => '/artists/123',
        :rel => '/children'
      }
      mapper = AcceptableModel::RelationshipsMapper.new :model => model, :response_block => structure
      mapper.response_block.call( stub(:class => Artist, :id => '123'), 'children' ).should eql expected
    end
  end

  describe "#associations" do
    let( :artist ) { 
      params = {
        :name => 'Busta Rhymes',
        :groups => ['Flipmode Squad', 'Leaders of The New School']
      }
      AcceptableModel::Artist.new params
    }
    let(:group1) { Group.new :name => 'Flipmode Squad', :id => 'flipmode-squad' }
    let(:group2) { Group.new :name => 'Leaders of The New School', :id => 'leaders-of-the-new-school' }
    let(:associations) { AcceptableModel::Artist.associations }

    before :each do
      class AcceptableModel::Artist
        version ['vnd.acme.artist-v1+json', 'vnd.acme.artist-v1+xml'] do |artist|
          {
            :id => artist.id,
            :name => artist.name
          }
        end

        relationship :groups
      end
      artist.groups.stub(:all).and_return [group1, group2]
    end

    after :each do
      class AcceptableModel::Artist
        undef part_of
      end
    end

    it "can take the a list of model associations" do
      mapper = AcceptableModel::RelationshipsMapper.new :model => artist, :associations => associations
      mapper.associations.should be_an Array
    end
  end

  describe "#relationships" do
    let( :artist ) { 
      params = {
        :name => 'Busta Rhymes',
        :groups => ['Flipmode Squad', 'Leaders of The New School']
      }
      AcceptableModel::Artist.new params
    }
    let(:structure) {
      Proc.new do |model, relationship|
        {
          :href => "/#{model.class.to_s.downcase.pluralize}/#{model.id}",
          :rel => "/#{relationship.camelize :lower}"
        }
      end
    }
    let(:group1) { Group.new :name => 'Flipmode Squad', :id => 'flipmode-squad' }
    let(:group2) { Group.new :name => 'Leaders of The New School', :id => 'leaders-of-the-new-school' }
    let(:associations) { AcceptableModel::Artist.associations }

    before :each do
      class AcceptableModel::Artist
        version ['vnd.acme.artist-v1+json', 'vnd.acme.artist-v1+xml'] do |artist|
          {
            "id " => artist.id,
            "name" => artist.name
          }
        end

        relationship :groups
      end
      artist.groups.stub(:all).and_return [group1, group2]
    end

    after :each do
      class AcceptableModel::Artist
        undef part_of
      end
    end

    it "creates the hash for the model"

    it "creates the hash for the links" do
      links = [
        {:href=>"/artists/busta-rhymes", :rel=>"/self"},
        {:href=>"/groups/flipmode-squad", :rel=>"/children"},
        {:href=>"/groups/leaders-of-the-new-school", :rel=>"/children"}
      ]

      mapper = AcceptableModel::RelationshipsMapper.new :model => artist, :associations => associations, :response_block => structure
      mapper.links.should eql links
    end

    it "creates the hash for the associations" do
      expected = {
        'groups' => [
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
      mapper = AcceptableModel::RelationshipsMapper.new :model => artist, :associations => associations, :response_block => structure
      mapper.relationships.should include expected
    end
  end
end
