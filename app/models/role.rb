
module Tombstone
  class Role < BaseModel
    set_primary_key :id
    many_to_one :person, {:key => :person_id}
    many_to_one :residential_contact, {:key => :residential_contact_id, :class => :'Tombstone::Contact'}
    many_to_one :mailing_contact, {:key => :mailing_contact_id, :class => :'Tombstone::Contact'}
    many_to_many :allocations, :join_table => :role_association, :left_key => :role_id, :right_key => [:allocation_id, :allocation_type], :class => :'Tombstone::Allocation'
    
    class << self
      def valid_types
        ['reservee', 'deceased', 'applicant', 'next_of_kin']
      end
    end
    
    def validate
      errors.add(:person, "must have an associated person") if !person
      errors.add(:residential_contact, "must have an associated residential contact") if !person
      errors.add(:type, "type must be one of: #{self.class.valid_types.join(', ')}") if !self.class.valid_types.include? type.downcase
    end
  end
end