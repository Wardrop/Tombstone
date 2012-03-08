require_relative '../spec_helper'
require_relative '../../app/lib/calendar'

module Tombstone
  describe Calendar do
    it "should return calendar entry" do
      calendar = Calendar.new
      calendar.iCal.should_not == nil
      calendar.iCal.events.size.should == 3
    end

    it "should return the same calendar descriptions and locations" do
      calendar = Calendar.new
      calendar.iCal.events[0].description.should == '[Pending] Mr Roger Fickle - Coffin with <Funeral Director Pending>'
      calendar.iCal.events[0].location.should == 'Mareeba Cemetery - Lawn - Row A - Plot 18'
      calendar.iCal.events[1].description.should == '[Approved] Mr Sam Bunson - Ashes with Guilfoyles Mareeba'
      calendar.iCal.events[1].location.should == 'Mareeba Cemetery - Lawn - Row A - Plot 17'
      calendar.iCal.events[2].description.should == '[Provisional] <Deceased Name Pending> - Ashes with Guilfoyles Atherton'
      calendar.iCal.events[2].location.should == 'Mareeba Cemetery - Lawn - Row A - Plot 16'
    end

  end

end
