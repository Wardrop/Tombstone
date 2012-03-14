PADRINO_ENV = 'spec' unless defined?(PADRINO_ENV)
require File.expand_path(File.dirname(__FILE__) + "/../config/boot")
require_relative 'models_spec_helper'

LDAP_USER = {username: 'lanuser', password: 'M@1lb0t!'}

# RSpec.configure do |conf|
#   conf.include Rack::Test::Methods
# end

# def app
#   ##
#   # You can handle all padrino applications using instead:
#   #   Padrino.application
#   Pilot.tap { |app|  }
# end
