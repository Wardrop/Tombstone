require_relative '../spec_helper'

module Tombstone
  describe Place do
    
    it "is configured correctly" do
      place = Place.with_pk(1)
      place.name.should include('Cemetery')
    end
    
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
    
    it "can have allocations" do
      plot = Place.with_pk(7)
      plot.allocations.should be_a(Array)
      plot.allocations[0].should be_a(Allocation)
    end
    
    it "can provide child count with result set" do
      places = Place.filter(:parent_id => 2).with_child_count.all
      places[0][:child_count].should == Place.filter(:parent_id => places[0].id).count
    end
    
    it "provides helper for determing whether interments are allowed" do
      Place.with_pk(10).allows_interment?.should == false # has children
      Place.with_pk(13).allows_interment?.should == false # in use
      Place.with_pk(14).allows_interment?.should == false # unavailable
      Place.with_pk(15).allows_interment?.should == true # vacant
      Place.with_pk(7).allows_interment?.should == true # multiple interments inherited from parent
    end
    
    it "gets all ancestors" do
      plot = Place.with_pk(7)
      plot.ancestors.should be_a(Array)
      plot.ancestors[0].should be_a(Place)
      plot.ancestors[0].type.should == 'row'
    end
    
    it "get all ancestors including self" do
      plot = Place.with_pk(13)
      anc = plot.ancestors(true)
      plot.ancestors.should be_a(Array)
      anc.length.should == 4
    end
    
    it "get all ancestors up to a specific ancestor" do
      plot = Place.with_pk(13)
      anc = plot.ancestors(false, 2)
      plot.ancestors.should be_a(Array)
      anc.length.should == 2
    end
    
    it "gets next available plot from any level" do
      na1 = Place.with_pk(3).next_available
      na1.should be_a(Place)
      [na1.id, na1.name].should == [15, 'Plot 5']
      
      na2 = Place.with_pk(11).next_available
      na2.name.should == 'Plot 38'
      
      na3 = Place.with_pk(2).next_available
      na3.name.should == 'Plot 22'
    end
    
    it "gets siblings including self" do
      plot = Place.with_pk(7)
      siblings = plot.siblings.all
      siblings.count.should > 1
      siblings.each { |s| s.parent_id.should == plot.parent_id}
      siblings.select { |s| s.id == plot.id }.length == 1
    end
    
  end
end
