Inpired by a conversation with @craigwebster I've been thinking lately about APIs and how to separate presentation logic from controllers and models in a clean way.
`
  class Artist
    attr_accessor :name, :albums, :songs, :debut

    def albums
      ['The coming', 'Disaster strikes']
    end

    def know_groups
      ['Leaders of the new school', 'Flipmode Squad']
    end
  end
`

`
  AcceptableModel.do |model|
    model.class: :artist
  end
`
This is how we like it, our models shouldn't know about presentation logic

By default AcceptableArtist will include all accessor methods that the Artist class exposes.

`
  class AcceptableArtist

    # /relationships/partOf
    #
    # It doesn't matter whether the method returns an Array, or object as
    # long as it has an id
    #
    def part_of
      know_groups
    end 

    #
    # /relationships/child
    #
    # The link is assumed by the name of the originating class and the
    # objects id
    #
    # => 
    #   {
    #     'rel': '/relations/child',
    #     'href': '/albums/the-coming'
    #   }
    #
    def children
      albums
    end
  end
`

In true DRY fashion there is not need define a links href as they will be looked up via our controllers.

`
  class Artists < Sinatra::Base
    get '/artists'
      AcceptableArtist.all
    end
  end

  class Groups < Sinatra::Base
    get '/collecions'
      Groups.all
    end
  end
`

`
  curl  -H 'Accept: application/json' -i http://localhost:9292/artist/busta-rhymes
`

`
{
  'name': 'Busta Rhymes',
  'debut': '1990'
  'albums': [
    'name': 'The Coming',
    'links': [
      {
        'href': '/albums/the-coming',
        'rel': '/relationships/children'
      }
    ]
  ],
  'songs': [
    {'title': 'Gimme Some more', 'duration': '4:05'}
  ]
  'links': [
    {
      'href': '/artists/cilla_black',
      'rel': '/relations/self',
    },
    {
      'href': '/collections/leaders-of-the-new-school',
      'rel': '/relations/partOf'
    },
    {
      'href': '/collections/Flipmode-squad',
      'rel': '/relations/partOf'
    }
  ]
}
`

