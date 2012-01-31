require_relative './models_helper'

class Reservation < Sequel::Model
  set_primary_key :id
  many_to_one :place, :class => :Place, :key => :place_id
  many_to_one :reservee, :class => :Role, :key => :reservee_id
end