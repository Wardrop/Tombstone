Sequel::Model.plugin :validation_helpers
Sequel::Model.plugin :json_serializer
Sequel::Model.plugin :association_dependencies
Sequel::Model.raise_on_typecast_failure = false

Sequel::Model.db = case Padrino.env
  when :production then
    Sequel.connect({
      adapter: 'tinytds',
      host: 'trcsql02.trc.local',
      user: 'trc\tombstone_user',
      password: '10Pippl$ah',
      database: 'Tombstone_Test'
    })
  when :development then
    Sequel.connect({
      adapter: 'tinytds',
      host: 'trcsql02.trc.local',
      user: 'trc\tombstone_user',
      password: '10Pippl$ah',
      database: 'Tombstone_Dev'
    })
  when :spec then
    Sequel.connect({
      adapter: 'tinytds',
      host: 'trcsql02.trc.local',
      user: 'trc\tombstone_user',
      password: '10Pippl$ah',
      database: 'Tombstone_Spec'
    })
end
