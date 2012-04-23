Inpired by a conversation with @craigwebster and from reading @avidgrimm's
'Objects on Rails' book I've been thinking lately about APIs and how to
separate presentation logic from controllers and models in a clean way.

So we have a model, that has a few associations and accessors
``
  class Artist
    attr_accessor :name, :albums, :songs, :debut

    def albums
      ['The coming', 'Disaster strikes']
    end

    def know_groups
      ['Leaders of the new school', 'Flipmode Squad']
    end
  end
``

Now it'd be cool if we could extend our output to include relationships between
information and provide a HATEOS like API without cluttering up a beautiful
slim models.

Inspired by reading Avid's 'Object on Rails' book, it'd be nice if we could
simply delegate to our created model and have a Presenter like model that deals
with all the presentational logic for us.

We want this to be with a little ceremony as possible and make sure that our
models truely stay separate from our presentation logic.

So we can define an object `AcceptableModel.define 'artist'` and then you have
a Presenter like object that deals with the models presentation features

``
  class Artists < Sinatra::Base
    get '/artists'
      AcceptableModel::Artist.all
    end
  end

  class Groups < Sinatra::Base
    get '/collecions'
      AcceptableModel::Groups.all
    end
  end
``

This is how we like it, our models shouldn't know about presentation logic

By default AcceptableArtist will include all accessor methods that the Artist
class exposes.

The cool thing about the rel attribute is that we can define our own, doing
this couldn't be easier. Re-open the defined class and simple create your own
Re-open the defined class and simple create your own
relationship.
``
  class AcceptableModel::Artist

    # /partOf
    #
    # It doesn't matter whether the method returns an Array, or object as
    # long as it has an id
    #
    def part_of
      know_groups
    end 

    #
    # /child
    #
    # The link is assumed by the name of the originating class and the
    # objects id
    #
    # => 
    #   {
    #     'rel': '/child',
    #     'href': '/albums/the-coming'
    #   }
    #
    def children
      albums
    end
  end
``

Defining these methods exposes the objects relationships, visiting the resource
`curl  -H 'Accept: application/json' -i http://localhost:9292/artists/busta-rhymes`
exposes the following response.

``
  {
    'name': 'Busta Rhymes',
    'debut': '1990'
    'albums': [
      'name': 'The Coming',
      'links': [
        {
          'href': '/albums/the-coming',
          'rel': '/child'
        }
      ]
    ],
    'songs': [
      {'title': 'Gimme Some more', 'duration': '4:05'}
    ]
    'links': [
      {
        'href': '/artists/cilla_black',
        'rel': '/self'
      },
      {
        'href': '/collections/leaders-of-the-new-school',
        'rel': '/partOf'
      },
      {
        'href': '/collections/Flipmode-squad',
        'rel': '/partOf'
      }
    ]
  }
``

All this from a few lines of code :D

AcceptableModel define a range of rel values but we should also be able to
create our own rel types, we could do this via the config method as follows:

``
  AcceptableModel.config do |config|
    config.relationships = %w{self contains part_of parent child}
  end
``

This will prefix all of our rel attribuetes with the string above

TODO
====

In true DRY fashion there is not need define a links href as they will be
looked up via our controllers.

Should be able to define associations that should include relationships

``
  class AcceptableArtist
    rel_associations :groups
  end
``

This allows you to define which methods should be included in the response body
along with their associated links.

When calling `model.all` the output will now be as following:

``
  {
    'name': 'Busta Rhymes',
    'debut': '1990'
    'albums': [
      'name': 'The Coming',
      'links': [
        {
          'href': '/albums/the-coming',
          'rel': '/children'
        }
      ]
    ]
  }
``

We should also be able to easily change the rel attributes so that we can fully
customised the way they are displayed. It would be nice if we could do
something like this:

``
  AcceptableModel.config do |config|
    config.rel_prefix = '/relations/'
  end
``

