require_relative './models_helper'

class Role < Sequel::Model
  set_primary_key :id
  one_to_many :relationships_from, {:key => :role1_id, :class => :Relationship}
  one_to_many :relationships_to, {:key => :role2_id, :class => :Relationship}
  many_to_one :party, {:key => :party_id}
  many_to_one :residential_address, {:key => :residential_address_id, :class => :Address}
  many_to_one :mailing_address, {:key => :mailing_address_id, :class => :Address}
  
  def relationships
    self.relationships_to.each { |v| v.flip_roles! }
    self.relationships_from + self.relationships_to
  end
end