
module Tombstone
  class Person < BaseModel
    set_primary_key :id
    one_to_many :roles, {:key => :person_id, :class => :'Tombstone::Role'}
  
    class << self
      def valid_titles
        ['Mr', 'Ms', 'Mrs', 'Miss', 'Sir', 'Lady', 'Doctor', 'Director', 'Executor', 'Manager']
      end
    end
    
    def name
      "#{title} #{given_name} #{middle_initials} #{surname}"
    end
    
    def validate
      super
      validates_includes self.class.valid_titles, :title
      validates_min_length 2, [:given_name, :surname]
      validates_presence [:date_of_birth, :gender]
      validates_includes ['male', 'female'], :gender
      errors.add(:date_of_birth, "must be before today") unless (date_of_birth.is_a?(Time) && date_of_birth < Date.today)
    end
    
    def roles_by_type(type)
      self.roles do |ds|
        ds.filter(:role__type => type).
          exclude(
            Allocation.
              left_join(:role_association, :allocation_id => :allocation__id, :allocation_type => :allocation__type).
              exclude(:status => 'deleted').filter(:role_association__role_id => :role__id).exists
          )
      end
    end
  end
end