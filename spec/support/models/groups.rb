class Group
  attr_accessor :name, :id
  attr_accessor :attributes

  def initialize params = {}
    self.name = params[:name]
    self.id = self.name.downcase.gsub(' ', '-')
    self.attributes = { :id => self.id }
    self.attributes.merge! params
  end

  def attributes
    @attributes ||= {:id => id, :name => name}
  end
end
