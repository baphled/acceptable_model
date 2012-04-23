require "active_support/inflector"
require "delegate"
require "json"

module AcceptableModel
  #
  # Define the Class that we want to define as having a relationship
  #
  def self.define model
    dynamic_name = "#{model.to_s.capitalize}"
    model_object = model.to_s.capitalize.constantize
    eval define_class dynamic_name
  end

  def self.define_class model_object
    """
    class #{model_object} < SimpleDelegator
      include HATEOS

      def initialize params
        @delegate_model = ::#{model_object}.new params
        super @delegate_model
      end

      def to_model
        __getobj__
      end

      def class
        __getobj__.class
      end
    end
    """
  end

  #
  # HATEOS based presentation for models
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

      def configure
        yield self
        true
      end
      alias :config :configure

      def relationship_types
        @relationship_types = %w{part_of parent child contains prev next same_as}
        @relationship_types = @relationship_types | AcceptableModel::HATEOS.relationships unless AcceptableModel::HATEOS.relationships.nil?
        @relationship_types
      end
    end

    module InstanceMethods
      attr_accessor :base_relationship

      attr_accessor :relationships
      private :relationships=

      #
      # Overide the models to_json method so that we can can display our
      # serialised data
      #
      def to_json options = {}
        opts = {:links => relationships}.merge! options
        attributes.merge! opts
        super attributes
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

