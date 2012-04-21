require "active_support/inflector"
require "delegate"

class AcceptableModel
  def self.define model
    dynamic_name = "Acceptable#{model.to_s.capitalize}"
    model_object = model.to_s.capitalize.constantize
    Object.const_set(dynamic_name, model_object)
  end
end

