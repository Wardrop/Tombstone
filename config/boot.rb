require 'logger'

# Defines our constants
PADRINO_ENV  = ENV["PADRINO_ENV"] ||= ENV["RACK_ENV"] ||= "development"  unless defined?(PADRINO_ENV)
PADRINO_ROOT = File.expand_path('../..', __FILE__) unless defined?(PADRINO_ROOT)

# Load our dependencies
require 'rubygems' unless defined?(Gem)
require 'bundler/setup'
Bundler.require(:default, PADRINO_ENV)

##
# Enable devel logging
#
Padrino::Logger::Config[:production]  = { :log_level => :devel, :stream => :to_file, :log_static => false }
Padrino::Logger::Config[:development] = { :log_level => :devel, :stream => :stdout, :log_static => true }
Padrino::Logger::Config[:spec]        = { :log_level => :devel, :stream => :stdout, :log_static => true }


##
# Add your before load hooks here
#
Padrino.before_load do
  
end

##
# Add your after load hooks here
#
Padrino.after_load do
  
end

Padrino.load!
