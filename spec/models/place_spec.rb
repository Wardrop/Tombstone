require_relative '../spec_helper'
require_relative 'models_spec_helper'

module Tombstone
  describe Place do
    
    it "can have a parent" do
      section = Place.with_pk(4)
      section.parent.should be_a(Place)
      section.parent.id.should == 2
      
      cemetery = Place.with_pk(1)
      cemetery.parent.should be_nil
    end
    
    it "can have childen" do
      section = Place.with_pk(4)
      section.children.length.should == 2
      section.children[0].id.should == 5
      
      plot = Place.with_pk(7)
      plot.children.should be_empty
    end
    
    it "can have a reservation" do
      plot = Place.with_pk(7)
      plot.reservation.should be_a(Reservation)
      plot.reservation.id.should == 1
    end
    
    it "can provide child count with result set" do
      places = Place.filter(:parent_id => 2).with_child_count.all
      places[0][:child_count].should be_nil
      places[1][:child_count].should == 2
    end
    
  end
end
