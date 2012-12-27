require_relative "enumerable"

module AcceptableModel
  module DSL
    module ClassMethods
      #
      # A list of associations mapped to the presenter
      #
      # Theses associations are linked to the delegated model and will be
      # included in the delegate models final HATEOAS structure.
      #
      attr_accessor :associations
      attr_accessor :versioned_associations

      #
      # List of versions mapped to the presenter
      #
      attr_accessor :version_mapper

      #
      # Maps API version and response type
      #
      def mime_types versions, &block
        @version_mapper = [] if @version_mapper.nil?
        versions.collect { |version| @version_mapper <<  {:version => version, :attributes => block } }
      end

      #
      # Maps API version and response type
      #
      # NOTE: Deprecated
      #
      def version versions, &block
        Kernel.warn %s{[DEPRECATION] `version` is deprecated.  Please use `mime_types` instead.}
        mime_types versions, &block
      end

      #
      # Map associations
      #
      # This macro is used to allow users to map associations to a model
      # allowing for a HATEOAS compliant format
      #
      def relationship association, versions = {}
        @versioned_associations = [] if @associations.nil?
        @versioned_associations << { association.to_s => versions }
      end

      #
      # Retrieves a list of associations for the model
      #
      # If the the version is passed we return the assocations based on that version
      #
      # #FIXME Would be nice to be able to set the version internally
      #
      def associations version = nil
        @versioned_associations = [] if @versioned_associations.nil?
        if version.nil?
          @versioned_associations.collect do |hash|
            hash.each_key.collect { |key, val| key }
          end.flatten
        else
          @versioned_associations.select do |hash|
            hash.find { |key, val| val != {} and val[:version].include? version }
          end.collect( &:keys ).flatten
        end
      end
    end
  
    module InstanceMethods
  
    end
  
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end
