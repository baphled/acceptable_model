require "acceptable_model"

require "json"

class Artist
  attr_accessor :name, :id, :groups
  include AcceptableModel::HateOS

  def initialize params = {}
    self.name = params[:name]
    self.groups = params[:groups]
    self.id = self.name.downcase.gsub(' ', '-')
  end

  def to_json
    super :name => name
  end

  protected

  def groups= groups
    @group = groups.each {|group| Group.new :name => group} unless groups.nil?
  end
end

class Group
  attr_accessor :name, :id
  def initialize params = {}
    self.name = params[:name]
    self.id = self.name.downcase.gsub(' ', '-')
  end

  def to_json
    super :name => name
  end
end

AcceptableModel.define 'artist'

describe AcceptableModel do
  describe "#define" do
    it "dyanmically defines a new class" do
      expect {
        AcceptableArtist.new :name => 'Busta Rhymes'
      }.to_not raise_error Exception
    end
  end

  context "a dynamically defined class" do
    it "exposes the originating models accessors" do
      model = AcceptableArtist.new :name => 'Busta Rhymes'
      model.name.should eql 'Busta Rhymes'
    end
  end

  describe "#to_json" do
    before :all do
      AcceptableModel.define 'group'
    end

    it "returns at HATEOS like format" do
      expected = {
        :links => [
          {
            :href => '/artists/busta-rhymes',
            :rel => '/self'
          }
        ],
        :name => 'Busta Rhymes'
      }.to_json
      model = AcceptableArtist.new :name => 'Busta Rhymes'
      model.to_json.should eql expected
    end

    context "extended relationships" do
      before do
        class AcceptableArtist
          def part_of
            groups.all
          end
        end
      end

      it "can extend the relationship links" do
        expected = {
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
          ],
          :name => 'Busta Rhymes'
        }.to_json
        model = AcceptableArtist.new :name => 'Busta Rhymes', :groups => ['Flipmode Squad', 'Leaders of The New School']
        group1 = Group.new :name => 'Flipmode Squad', :id => 'flipmode-squad'
        group2 = Group.new :name => 'Leaders of The New School', :id => 'leaders-of-the-new-school'
        model.groups.stub(:all).and_return [group1, group2]
        model.to_json.should eql expected
      end
    end
  end
end
