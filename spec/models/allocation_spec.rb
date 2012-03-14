require_relative '../spec_helper'

module Tombstone
  
  describe Allocation do
    it "is configured correctly" do
      alloc = Allocation.with_pk([1, 'reservation'])
      alloc.type.should == 'reservation'
    end
    
    it "has a place" do
      alloc = Allocation.with_pk([2, 'reservation'])
      alloc.place.should be_a(Place)
    end
    
    it "has many roles" do
      alloc = Allocation.with_pk([2, 'reservation'])
      alloc.roles.should be_a(Array)
      alloc.roles.length.should >= 2
      alloc.roles[0].should be_a(Role)
    end
    
    it "has a funeral director" do
      alloc = Allocation.with_pk([2, 'interment'])
      alloc.funeral_director.should be_a(FuneralDirector)
    end
    
    it "has many transactions" do
      alloc = Allocation.with_pk([2, 'reservation'])
      alloc.transactions.should be_a(Array)
      alloc.transactions[0].should be_a(Transaction)
    end
    
    it "auto-increments ID if none given" do
      max_id = Allocation.order(:id.desc).first.id
      new_alloc = Allocation.new.set(type: 'reservation').save(:validate => false)
      new_alloc.id.should == max_id+1
    end
    
    it "allows ID to be set manually" do
      new_alloc = Allocation.new.set(id: 65, type: 'reservation').save(:validate => false)
      new_alloc.id.should == 65
    end
    
    it "can filter roles by types" do
      alloc = Allocation.with_pk([2, 'reservation'])
      alloc.roles_by_type('reservee').should be_a(Array)
      alloc.roles_by_type('reservee')[0].should be_a(Role)
      alloc.roles_by_type(:reservee)[0].type.should == 'reservee'
    end
  end
  
  describe Reservation do
    it "only returns reservations" do
      Reservation.all.each { |r| r.type.should == 'reservation' }
    end
    
    it "accepts a single primary key" do
      reservation = Reservation.with_pk(2)
      reservation.id.should == 2
      reservation.type.should == 'reservation'
    end
    
    it "defaults type on creation" do
      reservation = Reservation.new({}).save(validate: false)
      reservation.type.should == 'reservation'
      reservation.delete
    end
  end
  
  describe Interment do
    it "only returns interments" do
      Interment.all.each { |r| r.type.should == 'interment' }
    end
    
    it "accepts a single primary key" do
      interment = Interment.with_pk(2)
      interment.id.should == 2
      interment.type.should == 'interment'
    end
    
    it "defaults type on creation" do
      interment = Interment.new({}).save(validate: false)
      interment.type.should == 'interment'
      interment.delete
    end

    it "calcuate the correct alert status" do

      valid_alert_statuses = ['danger', 'warning', 'ok']

      interment_date = (Time.now + (-1 * 60 * 60)).to_datetime
      thresholds = [12, 24, 168]
      interment = Interment.new
      interment.calculate_alert_status(valid_alert_statuses, thresholds, interment_date ).should == 'danger'

      interment_date = (Time.now + (1 * 60 * 60)).to_datetime
      interment.calculate_alert_status(valid_alert_statuses, thresholds, interment_date ).should == 'danger'

      interment_date = (Time.now + (13 * 60 * 60)).to_datetime
      interment.calculate_alert_status(valid_alert_statuses, thresholds, interment_date ).should == 'warning'

      interment_date = (Time.now + (30 * 60 * 60)).to_datetime
      interment.calculate_alert_status(valid_alert_statuses, thresholds, interment_date ).should == 'ok'

      interment_date = (Time.now + (200 * 60 * 60)).to_datetime
      interment.calculate_alert_status(valid_alert_statuses, thresholds, interment_date ).should == 'ok'

      interment_date = (Time.now + (1 * 60 * 60)).to_datetime
      interment.calculate_alert_status(valid_alert_statuses.reverse, thresholds, interment_date ).should == 'ok'

      interment_date = (Time.now + (13 * 60 * 60)).to_datetime
      interment.calculate_alert_status(valid_alert_statuses.reverse, thresholds, interment_date ).should == 'warning'

      interment_date = (Time.now + (25 * 60 * 60)).to_datetime
      interment.calculate_alert_status(valid_alert_statuses.reverse, thresholds, interment_date ).should == 'danger'

      interment_date = (Time.now + (200 * 60 * 60)).to_datetime
      interment.calculate_alert_status(valid_alert_statuses.reverse, thresholds, interment_date ).should == 'danger'

      ## Test alert rules

      interment.interment_date = (Time.now + (-1 * 60 * 60)).to_datetime
      interment.status = 'completed'
      interment.alert_status.should == 'ok'

      interment.interment_date = (Time.now + (1 * 60 * 60)).to_datetime
      interment.status = 'deleted'
      interment.alert_status.should == 'ok'

      ## pending rules

      interment.interment_date = (Time.now + (0 * 60 * 60)).to_datetime
      interment.status = 'pending'
      interment.alert_status.should == 'danger'

      interment.interment_date = (Time.now + (4 * 60 * 60)).to_datetime
      interment.status = 'pending'
      interment.alert_status.should == 'danger'

      interment.interment_date = (Time.now + (12 * 60 * 60)).to_datetime
      interment.status = 'pending'
      interment.alert_status.should == 'danger'

      interment.interment_date = (Time.now + (24 * 60 * 60)).to_datetime
      interment.status = 'pending'
      interment.alert_status.should == 'danger'

      interment.interment_date = (Time.now + (25 * 60 * 60)).to_datetime
      interment.status = 'pending'
      interment.alert_status.should == 'warning'

      interment.interment_date = (Time.now + (169 * 60 * 60)).to_datetime
      interment.status = 'pending'
      interment.alert_status.should == 'ok'

      interment.interment_date = (Time.now + (1000 * 60 * 60)).to_datetime
      interment.status = 'pending'
      interment.alert_status.should == 'ok'

      ## approved rules

      interment.interment_date = (Time.now + (0 * 60 * 60)).to_datetime
      interment.status = 'approved'
      interment.alert_status.should == 'ok'

      interment.interment_date = (Time.now + (13 * 60 * 60)).to_datetime
      interment.status = 'approved'
      interment.alert_status.should == 'warning'

      interment.interment_date = (Time.now + (25 * 60 * 60)).to_datetime
      interment.status = 'approved'
      interment.alert_status.should == 'warning'

      interment.interment_date = (Time.now + (200 * 60 * 60)).to_datetime
      interment.status = 'approved'
      interment.alert_status.should == 'danger'

      interment.interment_date = (Time.now + (0 * 60 * 60)).to_datetime
      interment.status = 'interred'
      interment.alert_status.should == 'ok'

      interment.interment_date = (Time.now + (13 * 60 * 60)).to_datetime
      interment.status = 'interred'
      interment.alert_status.should == 'ok'

      interment.interment_date = (Time.now + (25 * 60 * 60)).to_datetime
      interment.status = 'interred'
      interment.alert_status.should == 'warning'

      interment.interment_date = (Time.now + (200 * 60 * 60)).to_datetime
      interment.status = 'interred'
      interment.alert_status.should == 'danger'

    end
  end

end
