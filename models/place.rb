require_relative './models_helper'

class Place < Sequel::Model
  set_primary_key :id
  many_to_one :parent, :class => self, :key => :parent_id
  one_to_many :children, :class => self, :key => :parent_id
  one_to_many :reservation, :class => :Reservation, :key => :place_id
  # one_to_many :interments
  
  def_dataset_method(:with_child_count) do
    left_join(Place.group(:parent_id).select{[count(parent_id).as(child_count), :parent_id___child_parent_id]}, :child_parent_id => :id)
  end
end