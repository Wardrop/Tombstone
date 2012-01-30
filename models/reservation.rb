require_relative './models_helper'

class Reservation < Sequel::Model
  set_primary_key :id
  one_to_one :place, :class => :Place, :key => :id, :primary_key => :place_id
  one_to_one :reservee, :class => :Role, :key => :id, :primary_key => :reservee_id
end