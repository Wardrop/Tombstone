PADRINO_ENV = 'spec' unless defined?(PADRINO_ENV)
require File.expand_path(File.dirname(__FILE__) + "/../config/boot")
require_relative 'models_spec_helper'

# RSpec.configure do |conf|
#   conf.include Rack::Test::Methods
# end

# def app
#   ##
#   # You can handle all padrino applications using instead:
#   #   Padrino.application
#   Pilot.tap { |app|  }
# end
