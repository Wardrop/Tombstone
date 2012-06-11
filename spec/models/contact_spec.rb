require_relative '../spec_helper'

module Tombstone
  describe Contact do
    
    before :all do
      @contact_offset = Contact.count - 5
    end
    
    it "is configured correctly" do
      contact = Contact.with_pk(@contact_offset + 1)
      contact.street_address.length.should > 1
    end
    
    it "has associated roles through mailing address" do
      contact = Contact.with_pk(@contact_offset + 1)
      contact.roles_with_residential_contact[0].should be_a(Role)
    end
    
    it "has associated roles through residential address" do
      contact = Contact.with_pk(@contact_offset + 2)
      contact.roles_with_mailing_contact[0].should be_a(Role)
    end
    
    it "has associated funeral directors through mailing address" do
      contact = Contact.with_pk(@contact_offset + 1)
      contact.funeral_directors_with_mailing_contact[0].should be_a(FuneralDirector)
    end
    
    it "has associated funeral directors through mailing address" do
      contact = Contact.with_pk(@contact_offset + 1)
      contact.funeral_directors_with_residential_contact[0].should be_a(FuneralDirector)
    end
  end
end
