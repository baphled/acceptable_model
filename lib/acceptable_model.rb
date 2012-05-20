require "delegate"

require "acceptable_model/hateoas"
require "acceptable_model/enumerable"
require "acceptable_model/representation"
require "acceptable_model/relationships_mapper"

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
      include HATEOAS
      attr_accessor :attributes_block

      def initialize params
        @delegate_model = ::#{model_object}.new params
        super @delegate_model
      end

      #
      # Returns the correct response type in the expected format
      #
      # As long the mapping is similar to custom mime types and at least
      # follow the below example we are easily able to differentiate between
      # differing representations of a model.
      #
      # e.g. /*\-v1+json$/
      #
      # We are free to represent varying versions of a system without
      # complicating our models, controllers or duplicating our code base 
      #
      def for mime_type
        map  = version_lookup mime_type
        raise MimeTypeNotReckonised.new mime_type if map.nil?
        mime = mime_type_lookup mime_type
        format = 'to_' + mime
        representation(map[:attributes]).send format.to_sym
      end

      #
      # Return a HATEOAS presentation of the model
      #
      # FIXME: Make setting the class name as a key optional
      #
      def representation attributes_block
        Representation.new self.class.to_s.downcase => mapper(attributes_block).representation
      end

      #
      # Looks up the format that the response should be returned as
      #
      def mime_type_lookup mime_type
        respond_with = version_lookup mime_type
        strip_extra_header_info mime_type.split('+').last unless respond_with.nil?
      end

      #
      # Maps attributes to to representational model
      #
      def mapper attributes_block
        klass =  'AcceptableModel::#{model_object}'.constantize
        mapper = RelationshipsMapper.new :model => self, :response_block => self.response_block, :attributes_block => attributes_block, :associations => klass.associations
      end

      #
      # Looks up the representational version that should be returned
      #
      # This allows the interface user to have differing versions of the same model
      #
      def version_lookup mime_type
        mime_type = strip_extra_header_info mime_type
        klass = 'AcceptableModel::#{model_object}'.constantize
        mappers = klass.version_mapper
        mappers.detect { |mapper| mime_type == mapper[:version] }
      end

      protected

      #
      # Need to strip away any extra information passed on to a 'Accept' header
      #
      def strip_extra_header_info mime_type
        mime_type.gsub('application/','').gsub('text/','')
      end

      class << self
        #
        # A list of associations mapped to the presenter
        #
        # Theses associations are linked to the delegated model and will be
        # included in the delegate models final HATEOAS structure.
        #
        attr_accessor :associations

        #
        # List of versions mapped to the presenter
        #
        attr_accessor :version_mapper

        #
        # Maps API version and response type
        #
        # FIXME Change this to reponse
        #
        def version versions, &block
          @version_mapper = [] if @version_mapper.nil?
          versions.collect { |version| @version_mapper <<  {:version => version, :attributes => block } }
        end

        #
        # Map associations
        #
        # This macro is used to allow users to map associations to a model
        # allowing for a HATEOAS compliant format
        #
        def relationship association
          @associations = [] if @associations.nil?
          @associations << association.to_s unless @associations.include? association.to_s
        end

        def find params = {}
          model = super
          AcceptableModel::#{model_object}.new model.attributes
        end

        #
        # A collection of models needs to be dealt with in the same way as a
        # single model
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

      #
      # Set to the delegated model
      #
      def to_model
        __getobj__
      end

      #
      # Lies and tells us that this object is actually the delegated model 
      #
      def class
        __getobj__.class
      end
    end
    """
  end
end
