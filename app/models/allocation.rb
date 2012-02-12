
module Tombstone
  class Allocation < BaseModel
    set_primary_key [:id, :type]
    unrestrict_primary_key
    
    many_to_one :place, :class => :'Tombstone::Place', :key => :place_id
    many_to_many :roles, :join_table => :role_association, :left_key => [:allocation_id, :allocation_type], :right_key => :role_id, :class => :'Tombstone::Role'
    many_to_one :funeral_director, {:key => :funeral_director_id, :class => :'Tombstone::FuneralDirector'}
    
    class << self
      def valid_states
        ['provisional', 'pending', 'approved', 'completed', 'deleted']
      end
    end
    
    def validate
      validates_presence :place
      unless place.allocations.reject{ |v| v.type != 'reservation' }.empty?
        errors.add(:place, "is already associated with another allocation of the same type (#{type})")
      end
      errors.add(:place, 'must not have any children') if place.children.length >= 1
      validates_min_length 2, :status
      errors.add(:status, "must be one of: #{self.class.valid_states.join(', ')}") if !status || status.empty? || !self.class.valid_states.include?(status)
    end
    
    def roles_by_type(type)
      self.roles { |ds| ds.filter(type: type) }
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
    end
    
    def before_create
      self.type = 'reservation'
    end
  end
end