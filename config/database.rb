
Sequel.datetime_class = DateTime
Sequel.default_timezone = :local
# TinyTds::Client.default_query_options[:timezone] = :utc
Sequel::Dataset::TIMESTAMP_FORMAT = "'%Y-%m-%dT%H:%M:%S%N%z'"
Sequel::Model.plugin :validation_helpers
Sequel::Model.plugin :json_serializer
Sequel::Model.plugin :tactical_eager_loading
Sequel::Model.plugin :serialization
Sequel::Model.plugin :lazy_attributes
Sequel::Model.raise_on_typecast_failure = true
Sequel::Model.raise_on_save_failure = true
Sequel::Model.json_serializer_opts[:naked] = true

p PADRINO_ENV
Sequel::Model.db = case PADRINO_ENV.to_sym
  when :production then
    Sequel.connect({
      adapter: 'tinytds',
      host: 'trcsql01.trc.local',
      user: 'TRC\tombstone_user',
      password: '10Pippl$ah',
      database: 'Tombstone_Prod'
    })
  when :test then
    Sequel.connect({
      adapter: 'tinytds',
      host: 'trcsql02.trc.local',
      user: 'TRC\tombstone_user',
      password: '10Pippl$ah',
      database: 'Tombstone_Test'
    })
  when :development then
    Sequel.connect({
      adapter: 'tinytds',
      host: 'trcsql02.trc.local',
      user: 'TRC\tombstone_user',
      password: '10Pippl$ah',
      database: 'Tombstone_Dev',
      loggers: [Logger.new(nil)]
    })
  when :spec then
    Sequel.connect({
      adapter: 'tinytds',
      host: 'trcsql02.trc.local',
      user: 'TRC\tombstone_user',
      password: '10Pippl$ah',
      database: 'Tombstone_Spec'
    })
  when :migration then
    Sequel.connect({
      adapter: 'tinytds',
      host: 'trcsql02.trc.local',
      user: 'TRC\tombstone_user',
      password: '10Pippl$ah',
      database: 'Tombstone_Migration'
    })
end

Sequel::Model.db << 'SET DATEFORMAT DMY'
Sequel::Model.db << 'SET ANSI_NULLS ON'
Sequel::Model.db << 'SET CONCAT_NULL_YIELDS_NULL OFF'
Sequel::Model.db << 'SET TEXTSIZE 2147483647' # Required for storing binary files in SQL. Otherwise the default maximum size is 4kb.
