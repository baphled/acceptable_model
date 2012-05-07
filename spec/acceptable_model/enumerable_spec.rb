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
end
