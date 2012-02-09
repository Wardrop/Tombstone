
module Tombstone
  class Person < BaseModel
    set_primary_key :id
    one_to_many :roles, {:key => :person_id, :class => :'Tombstone::Role'}
  end
end