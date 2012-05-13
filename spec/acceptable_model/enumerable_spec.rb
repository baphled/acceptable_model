require "spec_helper"

describe "AcceptableModel::Enumerable" do
  before do
    AcceptableModel.define 'artist'
    artist_enum = [
      AcceptableModel::Artist.new(:name => 'Busta Rhymes', :aliases => ['Busta Bus']),
      AcceptableModel::Artist.new(:name => 'Jay-Z', :aliases => ['Jiggaman']),
    ]
    Artist.stub(:all).and_return artist_enum
  end

  it "enumerates all models" do
    AcceptableModel::Artist.all.should be_an AcceptableModel::Enumerable
  end

  describe "#for" do
    let(:relationships) {
      { :artists => [
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

      artist_enum = [
        Artist.new(:name => 'Busta Rhymes', :aliases => ['Busta Bus']),
        Artist.new(:name => 'Jay-Z', :aliases => ['Jiggaman']),
      ]
      Artist.stub(:all).and_return artist_enum
    end

    it "should be able to handle an array of objects that AcceptableModel knows about" do
      artists = AcceptableModel::Artist.all
      artists.for('vnd.acme.artist-v1+json').should eql relationships.to_json
    end

    it "should support XML also" do
      expected = File.open('spec/fixtures/artists.xml').read
      artists = AcceptableModel::Artist.all
      artists.for('vnd.acme.artist-v1+xml').should eql expected
    end
  end
end
