require_relative './models_helper'

class Party < Sequel::Model
  set_primary_key :id
  one_to_many :roles, {:key => :party_id, :class => :Role}
end