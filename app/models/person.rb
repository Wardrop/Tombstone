
module Tombstone
  class Person < BaseModel
    set_primary_key :id
    one_to_many :roles, {:key => :person_id, :class => :'Tombstone::Role'}
  
    class << self
      def valid_titles
        ['Mr', 'Ms', 'Mrs', 'Miss']
      end
    end
    
    
    def validate
      super
      validates_includes self.class.valid_titles, :title
      validates_min_length 2, [:given_name, :surname]
      errors.add(:date_of_birth, "must be before today") unless (date_of_birth.to_date < Date.today)
      validates_presence [:date_of_birth, :gender]
      validates_includes ['male', 'female'], :gender
    end
    
    def roles_by_type(type)
      self.roles { |ds| ds.filter(type: type) }
    end
  end
end