require_relative '../spec_helper'
require_relative 'models_spec_helper'

module Tombstone
  describe Allocation do
    
    it "is configured correctly" do
      alloc = Allocation.with_pk([1, 'reservation'])
      alloc.type.should == 'reservation'
    end
    
    it "has a place" do
      reservation = Allocation.with_pk([2, 'reservation'])
      reservation.place.should be_a(Place)
    end
    
    it "has many roles" do
      reservation = Allocation.with_pk([2, 'reservation'])
      reservation.roles.should be_a(Array)
      reservation.roles.length.should >= 2
      reservation.roles[0].should be_a(Role)
    end
    
    it "has a funeral director" do
      interment = Allocation.with_pk([2, 'interment'])
      interment.funeral_director.should be_a(FuneralDirector)
    end
    
    it "auto-increments ID if none given" do
      max_id = Allocation.order(:id.desc).first.id
      new_alloc = Allocation.create({type: 'reservation'})
      new_alloc.id.should == max_id+1
    end
    
    it "allows ID to be set manually" do
      new_alloc = Allocation.create({id: 65, type: 'reservation'})
      new_alloc.id.should == 65
    end
    
    it "can retrieve rows by type" do
      reservation = Allocation.with_pk([2, 'reservation'])
      reservee = reservation.roles_by_type('reservee')
      reservee.should be_a(Array)
      reservee[0].should be_a(Role)
      reservee[0].type.should == 'reservee'
    end
    
  end
end
