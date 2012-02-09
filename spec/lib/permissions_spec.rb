require_relative '../spec_helper'

module Tombstone
  describe Permissions do
    map = {
      :operator => {:can_approve => true, :can_create_burials => false, :invalid_option => true},
      :supervisor => {:can_approve => true, :can_create_burials => true, :can_delete_photos => true}
    }
    
    context "class" do
      it "defaults to an empty permissions map" do
        Permissions.map.should == {}
      end
      
      it "can set and get a permissions map" do
        Permissions.map = map
        Permissions.map.should == map
      end
      
      it "can provide all valid permission options" do
        Permissions.options.should be_a(Set)
        Permissions.options.should include(:can_approve, :can_create_burials, :can_delete_photos)
        Permissions.options.should_not include(:invalid_option)
      end
    end
    
    context "instance" do      
      it "uses default role if no role given" do
        Permissions.new.role.should == :default
      end
      
      it "takes an optional role name on instantiation" do
        Permissions.new(:operator).role.should == :operator
        Permissions.new('supervisor').role.should == :supervisor
      end
      
      it "generates permission methods for all valid options" do
        perms = Permissions.new(:operator)
        perms.should respond_to(:can_approve?)
        perms.should respond_to(:can_approve!)
        perms.should respond_to(:can_delete_photos?)
        perms.should respond_to(:can_manage_cemeteries!)
      end
      
      it "completely ignores invalid permissions" do
        perms = Permissions.new(:operator)
        perms.should_not respond_to(:invalid_option)
      end
      
      it "Generates methods for permissions the current role doesn't have" do
        perms = Permissions.new(:operator)
        perms.should respond_to(:can_delete_photos?)
        perms.should respond_to(:can_delete_photos!)
      end
      
      it "Should raise an error for permissions that don't exist" do
        perms = Permissions.new(:operator)
        perms.should_not respond_to(:can_mow_lawn?)
        perms.should_not respond_to(:can_mow_lawn!)
      end
      
      it "can return boolean values when checking permissions" do
        perms = Permissions.new(:operator)
        perms.can_approve?.should == true
        perms.can_create_burials?.should == false
      end
      
      it "can raise an error when checking permissions" do
        perms = Permissions.new(:operator)
        perms.can_approve! # Shouldn't raise error
        expect {
          perms.can_create_burials!
        }.to raise_error(PermissionsError)
      end
      
      it "allows the role to be changed" do
        perms = Permissions.new(:operator)
        perms.can_create_burials?.should == false
        perms.role = :supervisor
        perms.can_create_burials?.should == true
      end
      
    end
  
  end
end
