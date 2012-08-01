module Tombstone
  
  class Blob < BaseModel
    set_primary_key :id
    many_to_one :place, :key => [:place_id], :class => :'Tombstone::Place'
    delegate :thumbnail_dimensions, :to => self

    class << self
      def thumbnail_dimensions
      {
        width: 256,
        height: 160
      }
      end
    end
  end
  
end




