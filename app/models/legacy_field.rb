module Tombstone
  class LegacyField < BaseModel(:Legacy)
    set_primary_key [:allocation_id, :key, :value]
    one_to_many :allocations, :key => :allocation_id, :primary_key => :id, :class => :'Tombstone::Allocation'
  end
end