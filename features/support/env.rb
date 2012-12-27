require "mongoid"
require "mongoid_slug"

require "capybara"
require 'capybara/cucumber'

require "sinatra"
require "rack/accept"

require 'database_cleaner'
require 'database_cleaner/cucumber'

require 'pry'

require File.join File.dirname(__FILE__), '..', '..', 'lib', 'acceptable_model'

ENV['RACK_ENV'] = "test"

mongoid_config_file = File.join File.dirname(__FILE__), '..', '..', 'example', 'orms', 'config', 'mongoid.yml'
Mongoid.load!(mongoid_config_file)

begin
  DatabaseCleaner.strategy = :truncation
rescue NameError
  raise "You need to add database_cleaner to your Gemfile (in the :test group) if you wish to use it."
end
