require "delegate"

require "acceptable_model/hateos"
require "acceptable_model/enumerable"

module AcceptableModel
  #
  # Define the Class that we want to define as having a relationship
  #
  def self.define model
    dynamic_name = "#{model.to_s.capitalize}"
    raise ModelNotFound if not Object.const_defined? dynamic_name
    model_object = model.to_s.capitalize.constantize
    eval define_class dynamic_name
  end

  #
  # Dynamically define our presentational object
  #
  # We delegate to our original model so that we can get access to all of it's
  # business logic so that we don't have to worry about mixing presentational
  # details with business logic
  #
  def self.define_class model_object
    """
    class #{model_object} < SimpleDelegator
      include HATEOS

      def initialize params
        @delegate_model = ::#{model_object}.new params
        super @delegate_model
      end

      class << self
        attr_accessor :associations, :version_mapper

        #
        # Maps API version and MIME type
        #
        def version versions, &block
          @version_mapper = [] if @version_mapper.nil?
          versions.collect { |version| @version_mapper <<  {:version => version, :attributes => block } }
        end

        #
        # Map associations
        #
        # This macro is used to allow users to map associations to a model
        # allowing for a HATEOS compliant format
        #
        def relationship association
          @associations = [] if @associations.nil?
          @associations << association.to_s unless @associations.include? association.to_s
        end

        #
        # Overide the models #all method so that we can extend the array with
        # our own functionality
        #
        def all
          models = super
          models.collect! { |m| new m.attributes }
          AcceptableModel::Enumerable.new models
        end

        #
        # Delegate class methods to the correct object
        #
        def method_missing method, *args
          ::#{model_object}.send(method,args)
        end
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
end
