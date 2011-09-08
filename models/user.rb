module Tombstone
  class User
    include MySQLObject
    table 'person'
  end
end