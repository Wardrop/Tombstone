
module Tombstone
  class Contact < BaseModel
    set_primary_key :id
    one_to_many :roles_with_residential_contact, {:key => :residential_contact_id, :class => :'Tombstone::Role'}
    one_to_many :roles_with_mailing_contact, {:key => :mailing_contact_id, :class => :'Tombstone::Role'}
    one_to_many :funeral_directors_with_residential_contact, {:key => :residential_contact_id, :class => :'Tombstone::FuneralDirector'}
    one_to_many :funeral_directors_with_mailing_contact, {:key => :mailing_contact_id, :class => :'Tombstone::FuneralDirector'}
    
    class << self
      def valid_states
        ['ACT', 'NT', 'NSW', 'QLD', 'SA', 'TAS', 'VIC', 'WA']
      end
    end
    
    def validate
      validates_min_length 5, :street_address # Shortest possible street address would be something like a single-residence street, e.g Tu St
      validates_min_length 3, :town
      if state && !state.empty? && !self.class.valid_states.include?(state)
        errors.add(:state, ", if given, must be one of: #{self.class.valid_states.join(', ')}")
      end
      validates_integer :postal_code
      if email && !email.empty?  && email.match(/.+@.+/)
        errors.add(:email, ", if given, email address must be valid")
      end
      if email && !email.empty?  && email.match(/.+@.+/)
        errors.add(:email, ", if given, email address must be valid")
      end
    end
  end
end
