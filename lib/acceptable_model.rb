require "active_support/inflector"

module AcceptableModel
  def self.define model
    dynamic_name = "Acceptable#{model.to_s.capitalize}"
    model_object = model.to_s.capitalize.constantize
    Object.const_set(dynamic_name.to_sym, model_object)
    dynamic_name.constantize.extend HateOS
  end

  module HateOS
    module ClassMethods
    end
  
    module InstanceMethods
      attr_accessor :base_relationship

      attr_accessor :relationships
      private :relationships=

      def relationships
        relationships = extended_relationships.collect! { |relationship| build_relationship relationship }
        return base_relationship if relationships.empty?
        relationships.unshift( base_relationship ).flatten!
      end

      def to_json options = {}
        opts = {
          :links => relationships
        }.merge! options
        opts.to_json
      end

      protected

      def extended_relationships
        types = %w{part_of}.select { |type| self.public_methods(false).include? type.to_sym }
      end

      def build_relationship type
        send(type.to_sym).collect { |part| 
          {
            :href => "/#{part.class.to_s.downcase.pluralize}/#{part.id}",
            :rel => "/#{type.camelize :lower}"
          }
        }
      end

      def base_relationship
         [
           {
             :href => "/#{self.class.to_s.downcase.pluralize}/#{id}", :rel => '/self'
           }
         ]
      end
    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end

