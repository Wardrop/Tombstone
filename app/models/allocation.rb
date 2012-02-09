
module Tombstone
  class Allocation < BaseModel
    set_primary_key [:id, :type]
    unrestrict_primary_key
    many_to_one :place, :class => :'Tombstone::Place', :key => :place_id
    many_to_many :roles, :join_table => :role_association, :left_key => [:allocation_id, :allocation_type], :right_key => :role_id, :class => :'Tombstone::Role'
    many_to_one :funeral_director, {:key => :funeral_director_id, :class => :'Tombstone::FuneralDirector'}
    
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
end