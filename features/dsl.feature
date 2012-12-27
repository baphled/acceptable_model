Feature: Acceptable model DSL
  In order to simplify the way that API response structures are managed
  As a developer
  I want to be able to easily express response types

  Scenario: I should be able to define a custom mime type
    Given there is a artist with a name
    And the "artist" is defined as an AcceptableModel
    When I create the following custom mime types
    """
    class AcceptableModel::Artist
      mime_types ['application/vnd.acme.artist-v1+json'] do |artist|
        { :id => artist.slug, :name => artist.name }
      end
    end
    """
    And a service for "artists" has been created
    And I make a request for the "artists" resource "busta-rhymes" with "application/vnd.acme.artist-v1+json"
    Then I should see
    """
    {
      "artist": {
        "id": "busta-rhymes", 
        "name": "Busta Rhymes",
        "links": [
          {
            "href": "/artists/busta-rhymes",
            "rel": "/self"
          }
        ]
      }
    }
    """

  Scenario: I can define link relationships
    Given there is an artist associated to a group
    And the "artist" is defined as an AcceptableModel
    And the "group" is defined as an AcceptableModel
    When I create the following custom mime types
    """
    class AcceptableModel::Artist
      mime_types ['application/vnd.acme.artist-v1+json'] do |artist|
        { :id => artist.slug, :name => artist.name }
      end

      def part_of
        groups.all
      end
    end
    """
    And a service for "artists" has been created
    And I make a request for the "artists" resource "busta-rhymes" with "application/vnd.acme.artist-v1+json"
    Then I should see
    """
    {
      "artist": {
        "id": "busta-rhymes", 
        "name": "Busta Rhymes",
        "links": [
          {
            "href": "/artists/busta-rhymes",
            "rel": "/self"
          },
          {
            "href": "/groups/leaders-of-the-new-skool",
            "rel": "/partOf"
          }
        ]
      }
    }
    """
