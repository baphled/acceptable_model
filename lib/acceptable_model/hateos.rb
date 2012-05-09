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
        HATEOS.relationship_types.select { |type| extended_relationship? type }
      end

      protected
			 
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
