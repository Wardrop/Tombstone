# require_relative '../spec_helper'
#Tombstone.send :remove_const, :Permissions
#require_relative '../../app/lib/permissions'

module Tombstone
  describe Permissions do
    map = {
      :operator => {:can_approve => true, :can_edit => false, :invalid_option => true},
      :coordinator => {:can_approve => true, :can_edit => true, :can_delete_files => true}
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
        Permissions.options.should include(:can_approve, :can_edit, :can_delete_files)
        Permissions.options.should_not include(:invalid_option)
      end
    end

    context "instance" do
      it "uses default role if no role given" do
        Permissions.new.role.should == :default
      end

      it "takes an optional role name on instantiation" do
        Permissions.new(:operator).role.should == :operator
        Permissions.new('coordinator').role.should == :coordinator
      end

      it "generates permission methods for all valid options" do
        perms = Permissions.new(:operator)
        perms.should respond_to(:can_approve?)
        perms.should respond_to(:can_approve!)
        perms.should respond_to(:can_delete_files?)
        perms.should respond_to(:can_manage_cemeteries!)
      end

      it "completely ignores invalid permissions" do
        perms = Permissions.new(:operator)
        perms.should_not respond_to(:invalid_option)
      end

      it "Generates methods for permissions the current role doesn't have" do
        perms = Permissions.new(:operator)
        perms.should respond_to(:can_delete_files?)
        perms.should respond_to(:can_delete_files!)
      end

      it "Should raise an error for permissions that don't exist" do
        perms = Permissions.new(:operator)
        perms.should_not respond_to(:can_mow_lawn?)
        perms.should_not respond_to(:can_mow_lawn!)
      end

      it "can return boolean values when checking permissions" do
        perms = Permissions.new(:operator)
        perms.can_approve?.should == true
        perms.can_edit?.should == false
      end

      it "can raise an error when checking permissions" do
        perms = Permissions.new(:operator)
        perms.can_approve! # Shouldn't raise error
        expect {
          perms.can_edit!
        }.to raise_error(PermissionsError)
      end

      it "allows the role to be changed" do
        perms = Permissions.new(:operator)
        perms.can_edit?.should == false
        perms.role = :coordinator
        perms.can_edit?.should == true
      end

    end

  end
end
