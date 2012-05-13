require "active_support/all"
require "json"

require "acceptable_model/exceptions"

module AcceptableModel
  #
  # HATEOAS based representation for models
  #
  module HATEOAS
    class << self
      #
      # Configuration variables
      #
       
      #
      # Allows interface users to specify which relationships should be
      # returned when
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
        (relationships)? @relationship_types.concat( relationships ) : @relationship_types
      end
    end

    module InstanceMethods
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
      # A list of the model associations to include in the response
      #
      def relationships
        relationships = extended_relationships.collect! { |relationship| relationship_mapper relationship }
        return base_relationship if relationships.empty?
        relationships.unshift( base_relationship ).flatten!
      end

      #
      # Used to pass around the links structure we use to generate links
      # hashes.
      #
      # These are used to represent the list of links associated to the model
      #
      def response_block
        Proc.new do |model, relationship|
          {
            :href => "/#{model.class.to_s.downcase.pluralize}/#{model.id}",
            :rel => "/#{relationship.camelize :lower}"
          }
        end
      end

      #
      # Gather a list of relationships created by the user
      #
      def extended_relationships
        HATEOAS.relationship_types.select { |type| extended_relationship? type }
      end

      #
      # Check that the object has the relationship defined
      #
      def extended_relationship? relationship
        self.public_methods(false).include? relationship.to_sym
      end
    end

    def self.included(receiver)
      receiver.send :include, InstanceMethods
    end
  end
end
