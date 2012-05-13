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
        self.songs = params[:songs]
        self.debut = params[:debut]
        self.attributes = :id => self.id
        self.attributes.merge! params
      end

      def albums
        ['The coming', 'Disaster strikes']
      end

      def know_groups
        ['Leaders of the new school', 'Flipmode Squad']
      end
    end

Now it'd be cool if we could build upon our object to include relationships
between associations and provide a HATEOAS like API without cluttering up a
beautiful slim controllers.

It'd be nice if we could simply delegate to our created model and have a
Presenter like model that deals with all the presentational logic for
us.

We want this to be with a little ceremony as possible and make sure that our
models truely stay separate from our presentation logic.

So we can define an object `AcceptableModel.define 'artist'` and then you have
a Presenter like object that deals with our output.

So instead of calling a model directly we could do something like this:

    class Artists < Sinatra::Base
      get '/artists.json'
        artists = AcceptableModel::Artist.all
        artists.for('vnd.acme.artist-v1+json')
      end
    end

    class Groups < Sinatra::Base
      get '/collecions.xml'
        groups = AcceptableModel::Groups.all
        groups.for('vnd.acme.artist-v1+xml')
      end
    end

Wouldn't that be cool, our models shouldn't know about presentation
logic and our controller should be a thin as possible

By default AcceptableModel::Artist will include all accessor methods that the Artist
class exposes whilst knowing about how to deal with the models
relationships and representing this in a HATEOAS format.

### Separating presentation with versioning

This is all well and good but we may want to version our responses and
respond differently dependantly on the format and version specified by a
user.

Typically we would put these details in our controllers or create
seperate views.

AcceptableModel takes this one step further and totally removes the need
for either by providing a simple DSL to allow you to specify the
expected responses dependant on the version provided.

    class AcceptableModel::Artist
      version ['vnd.acme.artist-v1+json', 'vnd.acme.artist-v1+xml'] do |artist|
        {
          :id => artist.id,
          :name => artist.name
        }
      end

      version ['vnd.acme.artist-v2-json'] do |artist|
        {
          :id => artist.name,
          :name => artist.name
        }
      end

      def part_of
        groups.all
      end
    end

AcceptableModel doesn't try to deal with HTTP requests, it merely
creates a wrapper object that replicates the HATEOAS response format, so
calling `artist.for('vnd.acme.artist-v1+json')` returns the following response:

    {
      'id': 'busta-rhymes',
      'name': 'Busta Rhymes',
      'debut': '1990',
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
      'links': [
        {
          'href': '/artists/busta_rhymes',
          'rel': '/self'
        },
        {
          'href': '/collections/leaders-of-the-new-school',
          'rel': '/partOf'
        },
        {
          'href': '/collections/flipmode-squad',
          'rel': '/partOf'
        }
      ]
    }

or calling `artist.for('vnd.acme.artist-v1+xml')` would yield:

    <?xml version="1.0" encoding="UTF-8"?>
    <artist>
      <id>busta-rhymes</id>
      <name>Busta Rhymes</name>
      <groups>
        <group>
          <id>flipmode-squad</id>
          <name>Flipmode Squad</name>
          <links>
            <link>
              <href>/groups/flipmode-squad</href>
              <rel>/children</rel>
            </link>
          </links>
        </group>
        <group>
          <id>leaders-of-the-new-school</id>
          <name>Leaders of The New School</name>
          <links>
            <link>
              <href>/groups/leaders-of-the-new-school</href>
              <rel>/children</rel>
            </link>
          </links>
        </group>
      </groups>
      <links>
        <link>
          <href>/artists/busta-rhymes</href>
          <rel>/self</rel>
        </link>
        <link>
          <href>/groups/flipmode-squad</href>
          <rel>/partOf</rel>
        </link>
        <link>
          <href>/groups/leaders-of-the-new-school</href>
          <rel>/partOf</rel>
        </link>
      </links>
    </artist>

AcceptableModel can also use custom mime types determine the mime type
version to be requested. This in turn allows us to keep varying versions
models encapsulated as well as keeping our services scaleable

As this is the case you can simple call #for on the instance variable
and pass it the custom mime type and AcceptableModel will work out which
mime type and version should be returned.

### Adding relationships

The cool thing about the rel attribute is that we can define our own values,
doing this couldn't be easier. Re-open the defined class and simple create your
own Re-open the defined class and simple create your own relationship.

    class AcceptableModel::Artist

      #
      # It doesn't matter whether the method returns an Array, or object as
      # long as it has an id
      #
      def part_of
        know_groups
      end 

      #
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
      config.relationships = %w{services jobs queries}
    end

### Displaying model associations

In true DRY fashion there is not need define a links href as they will be
looked up via our controllers.

Should be able to define associations that should include relationships

    class AcceptableArtist
      relationship :groups
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

  * Add prefixes to relationships

We should also be able to easily change the rel attributes so that we can fully
customised the way they are displayed. It would be nice if we could do
something like this:

    AcceptableModel.config do |config|
      config.rel_prefix = '/relations/'
    end

  * Should be able to specify relationships types when using the relationships macro
  * hrefs and rels values should be attributes of the link element

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
