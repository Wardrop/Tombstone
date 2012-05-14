
module Tombstone
  class Person < BaseModel
    set_primary_key :id
    one_to_many :roles, :key => :person_id, :class => :'Tombstone::Role'
    
    class << self
      def valid_titles
        ['Mr', 'Ms', 'Mrs', 'Miss', 'Sir', 'Lady', 'Doctor', 'Director', 'Executor', 'Manager']
      end
      
      def search(terms)
        param_map = {
          given_name: proc { |v| "@GivenNameTerm = "+db.literal("%#{v}%") },
          middle_name: proc { |v| "@MiddleNameTerm = "+db.literal("%#{v}%") },
          surname: proc { |v| "@SurnameTerm = "+db.literal("%#{v}%") },
          date_of_birth: proc { |v| "@DOBTerm = #{db.literal(v)}" },
          date_of_death: proc { |v| "@DODTerm = #{db.literal(v)}" }, 
          gender: proc { |v| "@GenderTerm = #{db.literal(v)}" }
        }
        params = terms.select{ |k,v| param_map[k] }.map{ |k,v| param_map[k].call(v) }
        p "EXEC PersonSearch #{params.join(',')}"
        self.db["EXEC PersonSearch #{params.join(',')}"].to_a
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
      errors.add(:date_of_birth, "must be before today") { date_of_birth < Date.today }
    end
    
    # Filters
    def roles_by_type(type, allocation_dataset = Allocation)
      self.roles_dataset.filter(:role__type => type).
          filter(
            allocation_dataset.
              left_join(:role_association, :allocation_id => :allocation__id, :allocation_type => :allocation__type).
              exclude(:status => 'deleted').
              filter(:role_association__role_id => :role__id).
              exists
          )
    end
    
    def role_by_type(type)
      roles_by_type(type).first
    end
    
    # def role_count(type)
    #   Tombstone::Allocation.
    #     join(:role_association, :allocation_id => :id, :allocation_type => :type).
    #     join(:role, :id => :role_id, :type => type).
    #     exclude(:allocation__status => 'deleted').
    #     filter(:person_id => role.person_id).
    #     exclude(primary_key_hash.map{|k,v| ["allocation__#{k}".to_sym, v]}.sql_expr).
    #     count
    # end
    
  end
end