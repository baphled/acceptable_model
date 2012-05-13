require "spec_helper"

describe AcceptableModel::Representation do
  let( :params ) {
    {
      :links => [
        :href => '/foo-bar',
        :rel => '/children'
      ]
    }
  }
  it "takes a hash of parameters" do
    AcceptableModel::Representation.new params
  end

  it "returns the links node in the expected format" do
    representation = AcceptableModel::Representation.new params
    representation.to_xml.should eql "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<links>\n  <link href=\"/foo-bar\" rel=\"/children\"/>\n</links>\n"
  end

  it "can turn convert properties into XML elements" do
    params = { 'artist' =>
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
    expected = File.open('spec/fixtures/artist_with_groups.xml').read
    representation = AcceptableModel::Representation.new params
    representation.to_xml.should eql expected
  end
end
