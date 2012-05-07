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
      class_name = self.first.class.to_s.downcase.pluralize
      format = "to_#{mime}".to_sym
      attributes_for(mime_type).send format, :skip_types => true, :root => class_name
    end

    def attributes_for mime_type
      collect do |model|
        map = model.version_lookup mime_type
        model_attributes model, map[:attributes].call(model)
      end
    end

    def model_attributes model, attributes
      model.relationship_links.each{|association| attributes.merge! association }
      attributes.merge!( {:links => model.relationships} )
      attributes
    end
  end
end
