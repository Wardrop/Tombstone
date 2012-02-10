
module Tombstone
  class Person < BaseModel
    set_primary_key :id
    one_to_many :roles, {:key => :person_id, :class => :'Tombstone::Role'}
  
    def validate
      validates_min_length 2, :given_name
      validates_min_length 2, :surname
      validates_presence :date_of_birth
      errors.add(:gender, "must be one of either 'male' or 'female'") if ['male', 'female'].include? gender.downcase
    end
  end
end