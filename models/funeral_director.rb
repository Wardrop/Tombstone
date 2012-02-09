require_relative './base'

module Tombstone
  class FuneralDirector < BaseModel(:Funeral_Director)
    set_primary_key :id
    one_to_many :allocations, {:key => :funeral_director_id, :class => :'Tombstone::Allocation'}
    many_to_one :residential_contact, {:key => :residential_contact_id, :class => :'Tombstone::Contact'}
    many_to_one :mailing_contact, {:key => :mailing_contact_id, :class => :'Tombstone::Contact'}
  end
end