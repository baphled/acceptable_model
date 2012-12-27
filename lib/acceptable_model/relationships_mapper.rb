module AcceptableModel
  class RelationshipsMapper
    attr_accessor :model
    attr_accessor :associations
    attr_accessor :response_block
    attr_accessor :attributes_block
    attr_accessor :representation

    def initialize options = {}
      self.model = options[:model]
      self.associations = options[:associations]
      self.attributes_block = options[:attributes_block]
      self.response_block = options[:response_block]
    end

    #
    # The representation of the model with its relationships and links.
    #
    # This method is used when we want to get a HATEOAS like response.
    #
    def representation
      representation = attributes
      relationships.each { |relationship| representation.merge! relationship }
      representation.merge! :links => links
    end

    protected

    #
    # Gathers the models attributes
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
      relationships = map_relationships
      children = ( relationships.nil? )? [] : relationships
      children.unshift( response_block.call( model, 'self') )
    end

    #
    # Returns a list of all the models relationships
    #
    def relationships
      return [] if associations.nil?
      associations.collect { |related_association|
        { related_association.to_sym => model_attributes( model, related_association ) }
      }
    end

    def model_attributes model, related_association
      return [] if model.send(related_association.to_sym).nil?
      construct_relationship_hash model.send(related_association.to_sym)
    end

    protected

    #
    # Constructs a hash containing all of the models related models and thier
    # corresponding links
    #
    def construct_relationship_hash association
      if not enumerator_types.include? association.class
        association.attributes.merge! build_links association, 'children'
      else
        association.collect { |associated_model| 
          associated_model.attributes.merge! build_links associated_model, 'children'
        }
      end
    end

    def enumerator_types
      list = [Array]
      begin
        list << Mongoid::Relations::Targets::Enumerable
      rescue NameError
      end
      list
    end

    #
    # build the given models HATEOAS like links
    #
    # FIXME Not quite sure how to deal with links that are not children
    #
    def build_links model, relationship
      { :links => [ response_block.call(model, relationship) ] }
    end

    def map_relationships
      model.extended_relationships.collect { |association|
        model.send(association.to_sym).collect { |rel_model|
          response_block.call rel_model, association
        }
      }.flatten
    end
  end
end
