module AcceptableModel
  class RelationshipsMapper
    attr_accessor :model
    attr_accessor :associations
    attr_accessor :response_block
    attr_accessor :attributes_block

    def initialize options = {}
      self.model = options[:model]
      self.associations = options[:associations]
      self.attributes_block = options[:attributes_block]
      self.response_block = options[:response_block]
    end

    #
    # The representation of the model with its relationships and links.
    #
    # This method is used when we want to get a HATEOS like response.
    #
    def representation
      representation = attributes
      relationships.each { |relationship| representation.merge! relationship }
      representation.merge :links => links
    end

    #
    # Calls the attributes_block and passes the model to base on the response on
    #
    def attributes
      attributes_block.call model
    end

    #
    # Build the links structure which includes all the links relating to the model
    #
    # These include a link to the actual model along with its relationships
    #
    def links
      children = model.extended_relationships.collect { |association|
        model.send(association.to_sym).collect { |rel_model|
          response_block.call rel_model, association
        }
      }.flatten!
      children.unshift( response_block.call( model, 'self') )
    end

    #
    # Returns a list of all the models relationships
    #
    def relationships
      associations.collect { |related_model|
        {
          related_model.to_sym => 
          model.send(related_model.to_sym).collect { |associated_model| 
            associated_model.attributes.merge! :links => [ response_block.call(associated_model, 'children') ]
          }
        }
      }
    end
  end
end
