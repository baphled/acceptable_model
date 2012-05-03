# AcceptableModel

Inpired by a conversation with [@craigwebster](http://twitter.com/craigwebster) and from reading [@avdi](http://twitter.com/avdi)
[Objects on Rails](http://devblog.avdi.org/2011/11/15/early-access-beta-of-objects-on-rails-now-available-2) book I've been thinking lately about APIs and how to
separate presentation logic from controllers and models in a clean way.

So we have a model, that has a few associations and accessors

    class Artist
      attr_accessor :id, :attributes

      attr_accessor :name, :albums, :songs, :debut

      def initialize params = {}
        self.id = params[:name]
        self.attributes.merge! self.id
      end

      def albums
        ['The coming', 'Disaster strikes']
      end

      def know_groups
        ['Leaders of the new school', 'Flipmode Squad']
      end
    end

Now it'd be cool if we could build upon our object to include relationships
between information and provide a HATEOS like API without cluttering up a
beautiful slim models.

Inspired by reading Avid's '[Objects on Rails](http://devblog.avdi.org/2011/11/15/early-access-beta-of-objects-on-rails-now-available-2)' book, it'd be nice if we could
simply delegate to our created model and have a Presenter like model that deals
with all the presentational logic for us.

We want this to be with a little ceremony as possible and make sure that our
models truely stay separate from our presentation logic.

So we can define an object `AcceptableModel.define 'artist'` and then you have
a Presenter like object that deals with the models presentation features

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

This is how we like it, our models shouldn't know about presentation logic

By default AcceptableModel::Artist will include all accessor methods that the Artist
class exposes.

### Adding relationships

The cool thing about the rel attribute is that we can define our own values,
doing this couldn't be easier. Re-open the defined class and simple create your
own Re-open the defined class and simple create your own relationship.

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

Defining these methods exposes the objects relationships, visiting the resource

    artist = AcceptableModel::Artist.first
    Artist.to_json

exposes the following response.

    {
      'name': 'Busta Rhymes',
      'debut': '1990',
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
      ],
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

All this from a few lines of code :D

### Adding rel attributes

AcceptableModel define a range of rel values but we should also be able to
create our own rel types, we could do this via the config method as follows:

    AcceptableModel.config do |config|
      config.relationships = %w{self contains part_of parent child}
    end

### Displaying model associations

In true DRY fashion there is not need define a links href as they will be
looked up via our controllers.

Should be able to define associations that should include relationships

    class AcceptableArtist
      rel_associations :groups
    end

This allows you to define which methods should be included in the response body
along with their associated links.

When calling `model.all` the output will now be as following:

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

## TODO

We should also be able to easily change the rel attributes so that we can fully
customised the way they are displayed. It would be nice if we could do
something like this:

    AcceptableModel.config do |config|
      config.rel_prefix = '/relations/'
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
