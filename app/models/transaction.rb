
module Tombstone
  class Transaction < BaseModel
    set_primary_key [:allocation_id, :allocation_type, :receipt_no]
    unrestrict_primary_key
    many_to_one :allocation, :key => [:allocation_id, :allocation_type], :class => :'Tombstone::Allocation'
    
    def validate
      super
      validates_presence :receipt_no
      validates_max_length 32, :receipt_no
    end
  end
end