require "active_support/inflector"

module AcceptableModel
  #
  # Define the Class that we want to define as having a relationship
  #
  def self.define model
    dynamic_name = "Acceptable#{model.to_s.capitalize}"
    model_object = model.to_s.capitalize.constantize
    Object.const_set(dynamic_name.to_sym, model_object)
    dynamic_name.constantize.extend HateOS
  end

  #
  # HATEOS based presentation for models
  #
  module HateOS
    def self.relationship_types
      %w{part_of}
    end

    module InstanceMethods
      attr_accessor :base_relationship

      attr_accessor :relationships
      private :relationships=

      def to_json options = {}
        opts = {
          :links => relationships
        }.merge! options
        opts.to_json
      end

      protected

      #
      # A list of the models relationships
      #
      def relationships
        relationships = extended_relationships.collect! { |relationship| relationship_mapper relationship }
        return base_relationship if relationships.empty?
        relationships.unshift( base_relationship ).flatten!
      end

      #
      # Gather a list of relationships created by the user
      #
      def extended_relationships
        HateOS.relationship_types.select { |type| extended_relationship? type }
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

