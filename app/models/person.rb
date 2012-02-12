
module Tombstone
  class Person < BaseModel
    set_primary_key :id
    one_to_many :roles, {:key => :person_id, :class => :'Tombstone::Role'}
  
    def validate
      super
      validates_min_length 2, [:given_name, :surname]
      validates_presence [:date_of_birth, :gender]
      validates_includes ['male', 'female'], :gender
    end
  end
end