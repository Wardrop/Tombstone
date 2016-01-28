require_relative '../spec_helper'

module Tombstone
  describe FuneralDirector do

    it "is configured correctly" do
      fd = FuneralDirector.all.last
      fd.name.length.should > 6
    end

    it "has a residential and/or mailing contact" do
      fd = FuneralDirector.order(:id.desc).first
      fd.residential_contact.should be_a(Contact)
      fd.mailing_contact.should be_a(Contact)
    end

    it "has many allocations" do
      fd = FuneralDirector.with_pk(1)
      fd.allocations.should be_a(Array)
      fd.allocations[0].should be_a(Allocation)
    end

  end
end
