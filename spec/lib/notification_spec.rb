require_relative '../spec_helper'

module Tombstone
  describe Notification do

    it "initialise configuration" do
      Notification.config = {:email=>{:from=>"noreply@tombstone.trc.local", :to=>"tatej@trc.qld.gov.au", :subject=>'[##{interment.id}] Notification of Burial Approval'}}
      Notification.config.should_not == nil
      Notification.general = {:hostname => 'localhost', :port => 9292}
      Notification.config[:email][:from].should == "noreply@tombstone.trc.local"
    end

    it "set subject correctly" do
      interment = Interment.with_pk(3)
      interment.id.should == 3
      notification  = Notification.new(interment)
      notification.subject.should == "[#3] Notification of Burial Approval"
    end

    it "send text email" do
      interment = Interment.with_pk(3)
      notification  = Notification.new(interment)
      notification.sendMessage
    end

  end
end
