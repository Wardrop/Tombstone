module Tombstone
  class Role < BaseModel
    set_primary_key :id
    
    many_to_one :person, {:key => :person_id}
    many_to_one :residential_contact, {:key => :residential_contact_id, :class => :'Tombstone::Contact'}
    many_to_one :mailing_contact, {:key => :mailing_contact_id, :class => :'Tombstone::Contact'}
    many_to_many :allocations, :join_table => :role_association, :left_key => :role_id, :right_key => :allocation_id, :class => :'Tombstone::Allocation'
    
    class << self
      def valid_types
        ['reservee', 'deceased', 'applicant', 'next_of_kin']
      end
      
      # Creates a role from a hash map, handling all checks and validation internally.
      # Returns the resulting Role object on success, or nil otherwise.
      # All errors are recorded to the provided error object which is expected to be a Sequel::Model::Errors object.
      def create_from(hash, errors)
        role = nil
        db.transaction do
          if hash['person']['id']
            person = Person[hash['person']['id']]
            if person.nil?
              errors.add(:person, "with ID ##{hash['person']['id']} does not exist")
              raise Sequel::Rollback
            else
              person.set_valid_only(hash['person'])
              if person.valid?
                person.save
              else
                errors.add(:person, person.errors)
                raise Sequel::Rollback
              end
            end
          else
            person = Person.new(hash['person'])
            if person.valid?
              person.save
            else
              errors.add(:person, person.errors)
              raise Sequel::Rollback
            end
          end
          
          contacts = {}
          contacts[:residential_contact] = hash['residential_contact'] unless hash['residential_contact'].empty?
          contacts[:mailing_contact] = hash['mailing_contact'] unless hash['mailing_contact'].empty?
          contacts.each do |type, data|
            if data['id']
              contact = Contact[data['id']]
              if contact.nil?
                errors.add(type, "with ID ##{data['id']} does not exist")
                raise Sequel::Rollback
              else
                contact.set_valid_only(data)
                if contact.valid?
                  contact.save
                else
                  errors.add(type, contact.errors)
                  raise Sequel::Rollback
                end
              end
            else
              contact = Contact.new(data)
              if contact.valid?
                contact.save
              else
                errors.add(type, contact.errors)
                raise Sequel::Rollback
              end
            end
            contacts[type] = contact
          end
          
          role = self.new({
            type: hash['type'],
            person: person,
            residential_contact: contacts[:residential_contact],
            mailing_contact: contacts[:mailing_contact]
          })
          if role.valid?
            role.save
          else
            errors.merge!(role.errors)
            raise Sequel::Rollback
          end
        end
        
        role
      end
    end
    
    def validate
      super
      errors.add(:person, "must have an associated person") if !person
      errors.add(:person, "must have an associated contact") unless residential_contact || mailing_contact
      errors.add(:residential_contact, "cannot be shared between multiple people") if residential_contact && residential_contact.shared?
      errors.add(:mailing_contact, "cannot be shared between multiple people") if mailing_contact && mailing_contact.shared?
      validates_includes self.class.valid_types, :type
      errors.add(:type, "must be one of: #{self.class.valid_types.join(', ')}") if !self.class.valid_types.include? type.downcase
    end
  end
end