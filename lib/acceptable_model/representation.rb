require "builder"

#
# Gives us more control over the output we receive when automatically
# generating our HATEOAS responses.
#
module AcceptableModel
  class Representation
    def initialize params = {}
      @attributes = params
    end

    def to_xml params = {}
      xml = Builder::XmlMarkup.new :indent => 2
      xml.instruct!
      if params[:root]
        xml.__send__ params[:root] do |root|
          walk_node root, @attributes
        end
      else
        walk_node xml, @attributes
      end
      xml.target!
    end

    def to_hash
      @attributes
    end

    def walk_node node, attributes
      attributes.each do |k,v|
        if k.to_s == 'links'
          node.links do |node|
            attributes[k].collect do |link|
              node.link(link)
            end
          end
        elsif v.class == Hash
          node.__send__ k do |children|
            walk_node children, v
          end
        elsif v.class == Array
          node.__send__ k do |children|
            v.collect do |attr|
              node.__send__ k.to_s.singularize do |child|
                walk_node child, attr
              end
            end
          end
        else
          eval "node.#{ k } v"
        end
      end
    end
  end
end
