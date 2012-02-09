require_relative '../spec_helper'
require_relative './models_spec_helper'

module Tombstone
  describe Role do
    
    it "is configured correctly" do
      role = Role.with_pk(1)
      role.type.should == 'reservee'
    end
    
    it "has an associated person" do
      role = Role.with_pk(1)
      role.person.should be_a(Person)
    end
    
    it "has an associated mailing and residential contact" do
      role = Role.with_pk(1)
      role.residential_contact.should be_a(Contact)
      role.mailing_contact.should be_a(Contact)
      role.residential_contact.should_not == role.mailing_contact
    end
    
    it "has many associated allocations" do
      role = Role.with_pk(1)
      role.allocations.should be_a(Array)
      role.allocations[0].should be_a(Allocation)
    end
    
  end
end