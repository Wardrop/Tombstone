module Tombstone
  class Allocation < BaseModel
    set_primary_key :id
    unrestrict_primary_key

    many_to_one :place, :key => :place_id, :class => :'Tombstone::Place'
    many_to_many :roles, :join_table => :role_association, :left_key => :allocation_id, :right_key => :role_id, :class => :'Tombstone::Role'
    many_to_one :funeral_director, :key => :funeral_director_id, :class => :'Tombstone::FuneralDirector'
    one_to_many :transactions, :key => :allocation_id
    one_to_many :files, :key => :place_id, :primary_key => :place_id, :class => :'Tombstone::Blob'
    one_to_many :legacy_fields, :key => :allocation_id, :primary_key => :id, :class => :'Tombstone::LegacyField'

    class << self
      def valid_alert_statuses
        ['danger', 'warning', 'ok']
      end
      
      def required_roles
        []
      end
      
      def valid_roles
        []
      end
    end

    # Follows business rules to determine whether the given status is allowed based on the current state of the allocation
    def status_allowed(state)
      allowed_states = case status
      when 'provisional'
        ['pending', 'approved']
      when 'pending'
        ['approved']
      when 'approved'
        ['interred']
      when 'interred'
        ['completed']
      else
        []
      end
      
      allowed_states << status if self.class.valid_states.include?(state)
      allowed_states.include? state
    end
      
    def validate
      super
      self.class.required_roles.each do |role_type|
        errors.add(role_type.to_sym, "must be added") if roles.select { |r| r.type == role_type}.empty?
      end
      if not Place === place(true)
        errors.add(:place, 'cannot be empty and must exist')
      elsif place.children.count >= 1
        errors.add(:place, 'must not have any children')
      end
      validates_min_length 2, :status
    end

    def role_by_type(type)
      roles_by_type(type).first
    end
    
    def roles_by_type(type)
      self.roles.select { |r| r.type == type.to_s}
    end
    
    def check_warnings
      roles.each do |role|
        warnings.add(role.type, "does not have an associated contact") unless role.residential_contact || role.mailing_contact
      end
    end

  end

  class Reservation < Allocation
    set_dataset dataset.filter(:type => 'reservation')
    one_to_many :interments, :primary_key => :place_id, :key => :place_id, :class => 'Tombstone::Interment', :conditions => {status: 'deleted'}.sql_negate
    
    
    # def initialize
    #   super
    #   self.status ||= 'approved'
    # end
    
    class << self
      def valid_roles
        ['applicant', 'reservee', 'next_of_kin']
      end

      def required_roles
        []
      end

      def valid_states
        ['approved', 'deleted']
      end
    end

    def validate
      super
      if errors[:place].empty?
        errors.add(:place, "is unavailable") unless place.allows_reservation?(self)
      end
      
      if (not alternate_reservee.blank?) && role_by_type(:reservee)
        errors.add(:reservee, "must be either a person or an alternate reservee (i.e. family name), not both.")
      end
      
      if errors[:reservee].empty?
        role = role_by_type('reservee')
        if role && role.person.roles_by_type('reservee', self.class.exclude(primary_key_hash(true).sql_expr)).count > 0
          errors.add(:reservee, "cannot be used as the selected person already has a reservation.")
        end
      end
      validates_includes self.class.valid_states, :status
    end

    def before_create
      super
      self.type = 'reservation'
    end
  end

  class Interment < Allocation
    set_dataset dataset.filter(:type => 'interment')
    one_to_one :reservation, :primary_key => :place_id, :key => :place_id, :class => 'Tombstone::Reservation', :conditions => {status: 'deleted'}.sql_negate
    
    class << self
      def valid_roles
        ['deceased', 'next_of_kin']
      end

      def required_roles
        ['deceased']
      end

      def valid_states
        Interment.awaiting_action_states + ['completed', 'deleted']
      end

      def awaiting_action_states
        ['provisional', 'pending', 'approved', 'interred']
      end

      def valid_interment_types
        ['coffin', 'ashes']
      end
      
      def interment_duration
        90.minutes
      end
    end

    def interment_date_end
       interment_date + self.class.interment_duration
    end

    def alert_status
      if Interment.awaiting_action_states.include? status
        # internment date time < 24hrs and the status is either 'provisional' or 'pending' then 'danger'
        # internment date time >= 24hrs and <= 48hrs and the status is either 'provisional' or 'pending' then 'warning'
        # internment date time >= 48hrs and <= 168hrs and the status is either 'provisional' or 'pending' then 'ok'
        # internment date time >= 168hrs and the status is either 'provisional' or 'pending' then 'ok'
        return calculate_alert_status(Allocation.valid_alert_statuses, [24,48,168], interment_date) if ['provisional','pending'].include? status

        # internment date time < 12hrs and the status is either 'approved' then 'ok'
        # internment date time >= 12hrs and <= 168hrs and the status is either 'approved' then 'warning'
        # internment date time >= 168hrs and the status is either 'approved' then 'danger'
        return calculate_alert_status(Allocation.valid_alert_statuses.reverse, [12,168,999], interment_date, true) if ['approved'].include? status
        return calculate_alert_status(Allocation.valid_alert_statuses.reverse, [24,168,999], interment_date, true) if ['interred'].include? status
      end
      Allocation.valid_alert_statuses.last
    end

    def calculate_alert_status(valid_alert_statuses, hours_thresholds, interment_date, reverse=false)
      thresholds_reached = hours_thresholds.find_all{|threshold| self.has_alert_been_reached(threshold, interment_date, reverse)}
      return valid_alert_statuses[hours_thresholds.index(thresholds_reached.first)] unless thresholds_reached.empty?
      valid_alert_statuses.last
    end

    def has_alert_been_reached(hours_threshold, interment_date, reverse)
      if (reverse)
        return interment_date > (Time.now - (hours_threshold * 60 * 60)).to_datetime unless interment_date.nil?
      else
        return interment_date < (Time.now + (hours_threshold * 60 * 60)).to_datetime unless interment_date.nil?
      end
      false
    end
    
    def check_warnings
      super
      overlapping = self.class.
        exclude(primary_key_hash).
        exclude(status: 'deleted').
        where("interment_date >= ? AND interment_date <= ?",
              (interment_date.to_time - self.class.interment_duration).to_datetime,
              interment_date_end)
        overlapping.all.any? do |allocation|
        if allocation.place.cemetery == place.cemetery
          warnings.add :interment_date, "overlaps with one or more other interments in the same cemetery."
        end
      end
      
      # Reservation for deceased.
      deceased = self.role_by_type('deceased')
      if deceased && deceased.person.role_by_type('reservee')
        deceased.person.role_by_type('reservee').allocations_dataset.exclude(place_id: place_id).each do |res|
          warnings.add :deceased, "has a reservation for another place. Reservation ID is ##{res.id}."
        end
      end

      warnings.add(:interment_date, "is in the past.") { interment_date >= DateTime.now }
      interment_day = interment_date.strftime('%A')
      if ['Saturday', 'Sunday'].include? interment_day
        warnings.add(:interment_date, "falls on a #{interment_day}.")
      elsif not (8..17).include? interment_date.hour
        warnings.add(:interment_date, "falls outside of work hours.")
      end
      
    end

    def validate
      existing_status = self.class.with_pk(id).status
      if ['deleted', 'completed'].include?(existing_status)
        errors.add(:Interment, "of status 'deleted' or 'completed' cannot be modified.")
      end
        
      if status != 'deleted'
        super
        if errors[:place].empty?
          errors.add(:place, "is unavailable") unless place.allows_interment?(self)
        end
        if errors[:deceased].empty?
          role = role_by_type('deceased')
          if role.person.roles_by_type('deceased', self.class.exclude(primary_key_hash(true))).count > 0
            errors.add(:deceased, "cannot be used as the selected person is already deceased.")
          end
        end
        validates_includes self.class.valid_states, :status
        validates_presence :funeral_director
        validates_presence :funeral_service_location
        validates_min_length 2, :funeral_director_name
        validates_presence [:advice_received_date, :interment_date]
        validates_includes self.class.valid_interment_types, :interment_type
        errors.add(:advice_received_date, "cannot be be in the future") { advice_received_date.to_date <= Date.today }
        if errors[:interment_date].empty? && interment_date > DateTime.now && ['interred', 'completed'].include?(status)
          errors.add(:status, "cannot be '#{status}' for a future interment date.")
        end
        if status == 'completed'
          errors.add(:files, 'must be added before an allocation can be completed.') if files.empty?
        end
      end
    end

    def before_create
      super
      self.type = 'interment'
    end

  end
end