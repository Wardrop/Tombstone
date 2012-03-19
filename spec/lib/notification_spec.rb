require_relative '../spec_helper'

module Tombstone
  describe Notification do

    it "initialise configuration" do
      Notification.config = {
       :enabled => true,
        :email => {
            :from => 'noreply@tombstone.trc.local',
            :cc => 'tatej@trc.qld.gov.au',
            :subject => '[#<%= interment.id %>] Notification of Burial is "<%= interment.status.capitalize %>"',
            :body =>  "A request for a new burial is '<%= interment.status.capitalize %>'.
          Deceased: <%= deceased.title %> <%= deceased.given_name %> <%= deceased.surname %>
          Cemetery: <%= place.description %>
          Type: <%= interment.interment_type.capitalize %>
          At: <%= interment.interment_date.strftime('%A %d %B %Y') %>
          For more details <%= interment_site_url %>",
        },
        :status_rules => {
            :rule_1 => {:from_status => 'pending', :to_status => 'approved', :notify => 'tatej@trc.qld.gov.au'},
            :rule_2 => {:from_status => nil, :to_status => 'pending', :notify => 'tatej@trc.qld.gov.au'}
        }
    }
      Notification.config.should_not == nil
      Notification.general = {:hostname => 'localhost', :port => 9292}
      Notification.config[:email][:from].should == "noreply@tombstone.trc.local"
    end

    it "set subject correctly" do
      interment = Interment.with_pk(3)
      interment.id.should == 3
      notification = Notification.new(interment)
      notification.subject.should == '[#3] Notification of Burial is "Approved"'
    end

    it "executes invalid rules correctly" do
      interment = Interment.with_pk(3)
      notification = Notification.new(interment)
      interment.status = 'approved'
      interment.status = 'pending'
      notification.notify.size.should == 0
      notification.send_notifications
    end

    it "executes valid rules correctly" do
      interment = Interment.with_pk(3)
      notification = Notification.new(interment)
      interment.status = 'pending'
      interment.status = 'approved'
      notification.notify.size.should == 1
      notification.send_notifications
    end

    it "executes rules correctly" do
      interment = Interment.with_pk(3)
      notification = Notification.new(interment)
      interment.status = nil
      interment.status = 'pending'
      notification.notify.size.should == 1
      notification.send_notifications
    end

    it "executes no rules correctly" do
      interment = Interment.with_pk(3)
      notification = Notification.new(interment)
      interment.status = 'pending'
      interment.status = 'pending'
      notification.notify.size.should == 0
      notification.send_notifications
    end


  end
end
