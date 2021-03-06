require "active_support/all"
require "json"

module AcceptableModel
  #
  # Custom Array class so that we can take manipulate all models the same way
  # we do with a single model
  #
  class Enumerable < Array
    #
    # Allows us to call for when making a request for more than one model
    #
    def for mime_type
      mime = self.first.mime_type_lookup mime_type
      format = "to_#{mime}".to_sym
      attributes_for(mime_type).send format
    end

    protected

    def attributes_for mime_type
      attributes = collect do |model|
        map = model.version_lookup mime_type
        representation model, mime_type, map[:attributes]
      end
      class_name = self.first.class.to_s.downcase.pluralize
      Representation.new class_name => attributes
    end

    def representation model, mime_type, attributes_block
      mapper(model, mime_type, attributes_block).representation.to_hash
    end

    def mapper model, mime_type, attributes_block
      RelationshipsMapper.new(
        :model => model,
        :response_block => model.response_block,
        :attributes_block => attributes_block,
        :associations => eval("AcceptableModel::#{model.class}" ).associations(mime_type)
      )
    end

    def model_attributes model, attributes
      model.relationship_links.each{|association| attributes.merge! association }
      attributes.merge!( {:links => model.relationships} )
      attributes
    end
  end
end
