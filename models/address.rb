require_relative './models_helper'

class Address < Sequel::Model
  set_primary_key :id
  one_to_many :roles_with_residential_address, {:key => :residential_address_id, :class => :Role}
  one_to_many :roles_with_mailing_address, {:key => :mailing_address_id, :class => :Role}
end