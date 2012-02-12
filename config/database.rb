Sequel::Model.plugin :validation_helpers
Sequel::Model.raise_on_typecast_failure = false

Sequel::Model.db = case Padrino.env
  when :development then
    Sequel.connect({
      adapter: 'tinytds',
      host: 'vm02',
      user: 'VM02\administrator',
      password: 'Passw0rd',
      database: 'Tombstone_Dev'
    })
  when :production then
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
      host: 'vm02',
      user: 'VM02\administrator',
      password: 'Passw0rd',
      database: 'Tombstone_Spec'
    })
end
