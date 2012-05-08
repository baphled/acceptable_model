module AcceptableModel
  class RelationshipsMapper
    attr_accessor :model
    attr_accessor :associations
    attr_accessor :response_block

    def initialize options = {}
      self.model = options[:model]
      self.associations = options[:associations]
      self.response_block = options[:response_block]
    end

    def links
      children = associations.collect { |association|
        model.send(association.to_sym).collect { |rel_model|
          response_block.call rel_model, 'children'
        }
      }.flatten!
      children.unshift( response_block.call( model, 'self') )
    end

    def relationships
      associations.collect { |related_model|
        {
          related_model => 
          model.send(related_model).collect { |associated_model| 
            associated_model.attributes.merge! :links => [ response_block.call(associated_model, 'children') ]
          }
        }
      }
    end
  end
end
