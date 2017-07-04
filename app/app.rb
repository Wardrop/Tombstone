require 'yaml'
require 'bundler/setup'
Bundler.require(:default)

require_relative 'helpers'

module Tombstone
  DIR = File.dirname(__FILE__)
  VERSION = '1.4.7'

  c = YAML.load_file("#{DIR}/config.yml")
  CONFIG = c[ENV['RACK_ENV']] || c['default']

  db = Sequel.connect(CONFIG[:db])
  Sequel.extension :core_extensions
  Sequel.extension :migration
  Sequel::Migrator.run(db, File.expand_path('../db/migrations/', File.dirname(__FILE__)))

  Sequel::Model.db = db
  Sequel.datetime_class = DateTime
  Sequel.default_timezone = :local
  Sequel::Dataset::TIMESTAMP_FORMAT = "'%Y-%m-%dT%H:%M:%S%N%z'"
  Sequel::Model.plugin :validation_helpers
  Sequel::Model.plugin :json_serializer
  Sequel::Model.plugin :tactical_eager_loading
  Sequel::Model.plugin :serialization
  Sequel::Model.plugin :lazy_attributes
  Sequel::Model.plugin :dirty
  Sequel::Model.plugin :blacklist_security
  Sequel::Model.plugin :string_stripper
  Sequel::Model.raise_on_typecast_failure = true
  Sequel::Model.raise_on_save_failure = true
  Sequel::Model.json_serializer_opts[:naked] = true
  Sequel::Model.db << 'SET DATEFORMAT DMY'
  Sequel::Model.db << 'SET ANSI_NULLS ON'
  Sequel::Model.db << 'SET CONCAT_NULL_YIELDS_NULL OFF'
  Sequel::Model.db << 'SET TEXTSIZE 2147483647' # Required for storing binary files in SQL. Otherwise the default maximum size is 4kb.

  require_pattern "#{DIR}/models/**/*.rb", "#{DIR}/lib/**/*.rb", "#{DIR}/refinements/**/*.rb"

  Mail.defaults { delivery_method CONFIG[:email][:delivery_method] }
  Permissions.map = CONFIG[:roles]
  LDAP.servers = [*CONFIG[:ldap][:servers]]
  LDAP.domain = CONFIG[:ldap][:domain]
  LDAP.logger = Logger.new(STDOUT)

  if ENV['RACK_ENV'] != 'spec'
    Models = ObjectSpace.each_object(::Class).to_a.select { |k| k < BaseModel || k == BaseModel }.each do |m|
      if m.name
        model_name = m.name.split('::').last
        m.send(:include, ModelPermissions.const_get(model_name)) if ModelPermissions.const_defined? model_name
      end
    end
  end

  require_pattern "#{DIR}/controllers/**/*.rb"
end
