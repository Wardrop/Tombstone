
module Tombstone
  class Allocation < BaseModel    
    set_primary_key [:id, :type]
    unrestrict_primary_key
    
    many_to_one :place, :key => :place_id, :class => :'Tombstone::Place'
    many_to_many :roles, :join_table => :role_association, :left_key => [:allocation_id, :allocation_type], :right_key => :role_id, :class => :'Tombstone::Role'
    many_to_one :funeral_director, {:key => :funeral_director_id, :class => :'Tombstone::FuneralDirector'}
    one_to_many :transactions, {:key => [:allocation_id, :allocation_type], }
    
    def validate
      super
      
      self.class.valid_roles.each do |role_type|
        errors.add(role_type.to_sym, "must be added") if roles.select { |r| r.type == role_type}.empty?
      end

      if not Place === place
        errors.add(:place, 'cannot be empty and must exist')
      elsif place.children.length >= 1
        errors.add(:place, 'must not have any children')
      elsif !new? && changed_columns.include?(:place_id)
        max_interments = place.ancestors.reverse.reduce(1){|max, place| (place.max_interments.to_i > 0) ? place.max_interments : max}
        if place.allocations_dataset.filter(type: 'interment').count >= max_interments
          errors.add(:place, "has exceeded its maximum number of interments (#{max_interments})")
        end
      end
      validates_min_length 2, :status
    end
    
    def roles_by_type(type)
      self.roles { |ds| ds.filter(type: type.to_s) }
    end
    
    # Makes the identify column "id" optional, which is something MSSQL doesn't automatically support.
    def around_create
      if self.id
        self.db.run "SET IDENTITY_INSERT [#{self.class.table_name}] ON"
        super
        self.db.run "SET IDENTITY_INSERT [#{self.class.table_name}] OFF"
      else
        super
      end
    end
  
  end
  
  class Reservation < Allocation
    set_dataset dataset.filter(:type => 'reservation')
    
    class << self      
      def with_pk(id)
        self.first(:id => id)
      end
      
      def valid_roles
        ['reservee', 'applicant', 'next_of_kin']
      end
      
      def valid_states
        ['active', 'completed', 'deleted']
      end
    end
    
    def validate
      super
      unless errors[:place]
        if place.allocations_dataset.filter(type: 'reservation').length > 0
          errors.add(:place, "has already been reserved")
        end
      end
      validates_includes self.class.valid_states, :status
    end
    
    def before_create
      self.type = 'reservation'
    end
  end
  
  class Interment < Allocation
    set_dataset dataset.filter(:type => 'interment')
    
    class << self      
      def with_pk(id)
        self.first(:id => id)
      end
      
      def valid_roles
        ['deceased', 'applicant', 'next_of_kin']
      end
      
      def valid_states
        ['provisional', 'pending', 'approved', 'interred', 'completed', 'deleted']
      end
      
      def valid_interment_types
        ['coffin', 'ashes']
      end
    end
    
    def validate
      super
      validates_includes self.class.valid_states, :status
      validates_presence :funeral_director
      validates_min_length 5, :funeral_director_name
      validates_min_length 5, :funeral_service_location
      validates_presence [:advice_received_date, :interment_date]
      validates_includes self.class.valid_interment_types, :interment_type
    end
    
    def before_create
      self.type = 'interment'
    end
  end
end