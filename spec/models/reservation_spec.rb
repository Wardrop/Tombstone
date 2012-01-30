require_relative '../spec_helper'
require_relative 'models_spec_helper'

module Tombstone
  describe Reservation do
    
    it "has a place" do
      reservation = Reservation.with_pk(1)
      reservation.place.should be_a(Place)
      reservation.place.id.should == 7
    end
    
    it "has a reservee" do
      reservation = Reservation.with_pk(1)
      reservation.reservee.should be_a(Role)
      reservation.reservee.id.should == 1
    end
    
  end
end
