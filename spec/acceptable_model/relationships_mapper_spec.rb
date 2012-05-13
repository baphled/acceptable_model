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
  let( :mapper ) { 
    mapper_params = {
      :model => artist,
      :response_block => structure,
      :attributes_block => attributes,
      :associations => associations
    }
    AcceptableModel::RelationshipsMapper.new mapper_params
  }

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

  describe "#representation" do
    it "includes the models attributes" do
      expected = {:id=>"busta-rhymes", :name=>"Busta Rhymes"}
      mapper.representation.to_hash.should include expected
    end

    it "includes the models associations" do
      links = {
        :links => [
          {:href=>"/artists/busta-rhymes", :rel=>"/self"},
          {:href=>"/groups/flipmode-squad", :rel=>"/partOf"},
          {:href=>"/groups/leaders-of-the-new-school", :rel=>"/partOf"}
        ]
      }
      mapper.representation.to_hash.should include links
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

      mapper.representation.to_hash.should include expected
    end

    it "should not include attributes we don't care about" do
      mapper.representation.to_hash.should_not include :groups => ["Flipmode Squad", "Leaders of The New School"]
    end

    it "can represent a one to one relationship" do
      class Alias
        attr_accessor :id, :name
        attr_accessor :attributes

        def initialize params = {}
          self.name = params[:name]
          self.id = self.name.downcase.gsub(' ', '-')
          self.attributes = { :id => self.id }
          self.attributes.merge! params
        end
      end

      class AcceptableModel::Artist
        relationship :alias
        def alias
          Alias.new :name => 'Busta Bus'
        end
      end
      expected = { :alias => {:id=>"busta-bus", :name=>"Busta Bus", :links=>[{:href=>"/aliases/busta-bus", :rel=>"/children"}]} }
      AcceptableModel::RelationshipsMapper.new :model => artist, :response_block => structure, :attributes_block => attributes, :associations => associations
      mapper.representation.to_hash.should include expected
    end
  end
end
