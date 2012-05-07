require "spec_helper"

describe AcceptableModel::HATEOS do
  it "should have a list of relationship types" do
    AcceptableModel::HATEOS.relationship_types.should eql %w{part_of parent child contains prev next same_as}
  end

  describe "#config" do
    it "allows us to add our own rel types" do
      AcceptableModel::HATEOS.config do |config|
        config.relationships = %w{service}
      end
      AcceptableModel::HATEOS.relationship_types.should include 'service'
    end
  end

  describe "#relationship" do
    before do
      AcceptableModel.define 'artist'
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
        'links' => [
          {
            'href' => '/artists/busta-rhymes',
            'rel' => '/self'
          }
        ]
      }.to_json
      model = AcceptableModel::Artist.new :name => 'Busta Rhymes', :groups => ['Flipmode Squad', 'Leaders of The New School']
      model.to_json.should eql expected
    end
  end
end
