require_relative '../spec_helper'

module Tombstone
  describe Contact do
    it "is configured correctly" do
      contact = Contact.with_pk(1)
      contact.email.should include('@')
    end
    
    it "has associated roles through mailing address" do
      contact = Contact.with_pk(1)
      contact.roles_with_residential_contact[0].should be_a(Role)
    end
    
    it "has associated roles through residential address" do
      contact = Contact.with_pk(2)
      contact.roles_with_mailing_contact[0].should be_a(Role)
    end
    
    it "has associated funeral directors through residential address" do
      contact = Contact.with_pk(6)
      contact.funeral_directors_with_residential_contact[0].should be_a(FuneralDirector)
    end
    
    it "has associated funeral directors through residential address" do
      contact = Contact.with_pk(6)
      contact.funeral_directors_with_mailing_contact[0].should be_a(FuneralDirector)
    end
  end
end
