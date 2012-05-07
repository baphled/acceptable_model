require "active_support/all"
require "json"

require "acceptable_model/exceptions"

module AcceptableModel
  #
  # HATEOS based representation for models
  #
  module HATEOS
    class << self
      #
      # Configuration variables
      #
      attr_accessor :relationships

      #
      # A complete list of relationship types to look for
      #
      attr_accessor :relationship_types

      #
      # Simple configuration block to allow interface users to define their own
      # custom relationships
      #
      def configure
        yield self
        true
      end
      alias :config :configure

      #
      # A list of all relationship types that the module knows about
      #
      def relationship_types
        @relationship_types = %w{part_of parent child contains prev next same_as}
        merge_relationships
      end

      protected

      #
      # Merge pre-defined relationships with those created by the interface
      # user
      #
      def merge_relationships
        @relationship_types.concat relationships if relationships
        @relationship_types
      end
    end

    module InstanceMethods
      attr_accessor :base_relationship
      private :base_relationship=

      #
      # All the associations the AcceptableModel should know about
      # 
      attr_accessor :associations
      private :associations=

      #
      # A list of all relationships the AcceptableModel is aware of
      #
      attr_accessor :relationships
      private :relationships=

      #
      # Looks up the format that the response should be returned as
      #
      def mime_type_lookup mime_type
        respond_with = version_lookup mime_type
        mime_type.split('+').last unless respond_with.nil?
      end

      #
      # Looks up the representational version that should be returned
      #
      # This allows the interface user to have differing versions of the same model
      #
      def version_lookup mime_type
        mappers = eval( "AcceptableModel::#{ self.class }" ).version_mapper
        mappers.detect { |mapper| mime_type == mapper[:version] }
      end

      #
      # A list of the model relationships
      #
      def relationships
        relationships = extended_relationships.collect! { |relationship| relationship_mapper relationship }
        return base_relationship if relationships.empty?
        relationships.unshift( base_relationship ).flatten!
      end

      def relationship_links
        associations = eval( "AcceptableModel::#{ self.class }" ).associations
        return [] if associations.nil?
        associations.collect { |association| 
          return [] if send(association.pluralize.to_sym).nil?
          build_association association
        }
      end

      #
      # Override the models to_json method so that we can can display our
      # HATEOS formatted data
      #
      def to_json options = {}
        opts = collect_attributes options
        attributes.merge(opts).to_json
      end

      #
      # Build our XML response using builder
      #
      # FIXME:Should flag those attributes that should be wrapped in CDATA tags 
      # FIXME links should be in the HTML link format ('<link href="http://google.com" rel="parent" />') 
      #
      def to_xml options = {}
        opts = collect_attributes options
        attributes.merge(opts).to_xml :skip_types => true, :root => self.class.to_s.downcase
      end

      protected

      def collect_attributes options
        relationship_links.each{|association| attributes.merge! association }
        {:links => relationships}.merge options
      end

      def build_association association
        {
          association.pluralize.to_sym => 
          send(association.pluralize.to_sym).collect { |model| 
            model.attributes.merge! build_relationship model, association
          }
        }
      end

      #
      # Dynamically builds associative relationships
      #
      # FIXME: Should be able to define link relationships
      #
      def build_relationship model, association
        {
          :links => [
            {
              :href => "/#{association.pluralize}/#{model.id}",
              :rel => "/children"
            }
          ]
        }
      end

      #
      # Gather a list of relationships created by the user
      #
      def extended_relationships
        HATEOS.relationship_types.select { |type| extended_relationship? type }
      end

      #
      # Check that the object has the relationship defined
      #
      def extended_relationship? relationship
        self.public_methods(false).include? relationship.to_sym
      end

      #
      # Maps the relationship to the format we expect
      #
      def relationship_mapper relationship
        send(relationship.to_sym).collect { |part| 
          {
            :href => "/#{part.class.to_s.downcase.pluralize}/#{part.id}",
            :rel => "/#{relationship.camelize :lower}"
          }
        }
      end

      #
      # Our response object always has a reference to itself
      #
      def base_relationship
        [
          {
            :href => "/#{self.class.to_s.downcase.pluralize}/#{id}",
            :rel => '/self'
          }
        ]
      end
    end

    def self.included(receiver)
      receiver.send :include, InstanceMethods
    end
  end
end
