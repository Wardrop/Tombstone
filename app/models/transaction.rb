
module Tombstone
  class Transaction < BaseModel
    set_primary_key [:allocation_id, :receipt_no]
    unrestrict_primary_key
    many_to_one :allocation, :key => :allocation_id, :class => :'Tombstone::Allocation'
    
    def validate
      super
      validates_min_length 1, :receipt_no
      validates_max_length 32, :receipt_no
    end
  end
end