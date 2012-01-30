require_relative '../spec_helper'
require_relative 'models_spec_helper'

module Tombstone
  describe Relationship do
    
    it "is associated with many roles" do
      relationship = Relationship.with_pk(1)
      relationship.source_role.should be_a(Role)
      relationship.source_role.id.should == 1
      relationship.target_role.should be_a(Role)
      relationship.target_role.id.should == 2
    end
    
    context "flipping" do
      it "indicates whether flipped or not" do
        relationship = Relationship.with_pk(1)
        relationship.flipped?.should == false
        relationship.flip_roles!
        relationship.flipped?.should == true
      end
      
      it "can flip the source and target roles" do
        relationship = Relationship.with_pk(1)
        original_primary = relationship.primary_role
        original_secondary = relationship.secondary_role
        relationship.flip_roles!
        relationship.primary_role.should == original_secondary
        relationship.secondary_role.should == original_primary
      end
      
      it "can unflip the source and target roles" do
        relationship = Relationship.with_pk(1)
        original_primary = relationship.primary_role
        relationship.flip_roles!
        relationship.unflip_roles!
        relationship.primary_role.should == original_primary
      end
    end
    
  end
end
