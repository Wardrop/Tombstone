
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

    # Whether or not this contact is shared between people.
    def shared?
      Role.filter({residential_contact_id: id, mailing_contact_id: id}.sql_or).select(:person_id).distinct.count > 1
    end

    def validate
      super
      validates_min_length 5, :street_address # Shortest possible street address would be something like a single-residence street, e.g Tu St
      validates_min_length 3, :town
      # if state && !state.empty? && !self.class.valid_states.include?(state)
      #   errors.add(:state, ", if given, must be one of: #{self.class.valid_states.join(', ')}")
      # end
      validates_min_length 1, :state
      validates_min_length 1, :country
      validates_min_length 4, :postal_code
      if !email.blank? && !email.match(/.+@.+/)
        errors.add(:email, "must be valid, if given")
      end
      unless primary_phone.blank?
        validates_min_length 6, :primary_phone
        errors.add(:primary_phone, "contains invalid characters.") if primary_phone && !primary_phone.match(/^[ 0-9\.\-+()x]*$/)
      end
      unless secondary_phone.blank?
        validates_min_length 6, :secondary_phone
        errors.add(:secondary_phone, "contains invalid characters.") if secondary_phone && !secondary_phone.match(/^[ 0-9\.\-+()x]*$/)
      end
    end
  end
end
