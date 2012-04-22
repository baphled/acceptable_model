require "active_support/inflector"

module AcceptableModel
  def self.define model
    dynamic_name = "Acceptable#{model.to_s.capitalize}"
    model_object = model.to_s.capitalize.constantize
    Object.const_set(dynamic_name, model_object)
    dynamic_name.constantize.extend HateOS
  end

  module HateOS
    module ClassMethods
    end
  
    module InstanceMethods
      attr_accessor :links

      def links
        [
          {
            :href => "/#{self.class.to_s.downcase.pluralize}/#{id}",
            :rel => '/self'
          }
        ]
      end

      def to_json options = {}
        opts = {
          :links => links
        }.merge! options
        opts.to_json
      end
    end
  
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end

