
module Tombstone
  class Contact < BaseModel
    set_primary_key :id
    one_to_many :roles_with_residential_contact, {:key => :residential_contact_id, :class => :'Tombstone::Role'}
    one_to_many :roles_with_mailing_contact, {:key => :mailing_contact_id, :class => :'Tombstone::Role'}
    one_to_many :funeral_directors_with_residential_contact, {:key => :residential_contact_id, :class => :'Tombstone::FuneralDirector'}
    one_to_many :funeral_directors_with_mailing_contact, {:key => :mailing_contact_id, :class => :'Tombstone::FuneralDirector'}
  end
end