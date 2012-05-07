class Artist
  attr_accessor :name, :aliases, :id, :groups
  attr_accessor :attributes

  def initialize params = {}
    self.name = params[:name]
    self.aliases = params[:aliases]
    self.groups = params[:groups]
    self.id = self.name.downcase.gsub(' ', '-')
    self.attributes = { :id => self.id }
    self.attributes.merge! params
  end

  protected

  def groups= groups
    @groups = groups.collect {|group| Group.new :name => group} unless groups.nil?
  end
end

