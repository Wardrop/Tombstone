Sequel::Model.plugin :validation_helpers
Sequel::Model.plugin :json_serializer
Sequel::Model.raise_on_typecast_failure = false
Sequel::Model.raise_on_save_failure = true
Sequel::Model.json_serializer_opts[:naked] = true

Sequel::Model.db = case Padrino.env
  when :production then
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
end

# Set the default date from that stupid american MDY to the more sane DMY.
Sequel::Model.db << 'SET DATEFORMAT DMY'