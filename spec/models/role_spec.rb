require_relative '../spec_helper'
require_relative './models_spec_helper'

module Tombstone
  describe Role do
    
    it "has an associated mailing and residential address" do
      role1 = Role.with_pk(1)
      role1.residential_address.should be_a(Address)
      role1.mailing_address.should be_a(Address)
      role1.residential_address.should_not == role1.mailing_address
    end
    
    it "has an associated party" do
      role1 = Role.with_pk(1)
      role1.party.should be_a(Party)
    end
    
    context "relationships" do
      it "has relationships from" do
        role3 = Role.with_pk(3)
        role3.relationships_from.count.should == 1
        role3.relationships_from.first.should be_a(Relationship)
      end
      
      it "has relationships to" do
        role3 = Role.with_pk(3)
        role3.relationships_to.count.should == 1
        role3.relationships_to.first.should be_a(Relationship)
      end
      
      it "can provide all relationships" do
        role3 = Role.with_pk(3)
        role3.relationships.length.should == 2
        role3.relationships.each do |rel|
          rel.should be_a(Relationship)
          rel.primary_role.should == role3
        end
      end
    end
  end
  
end