require_relative '../spec_helper'

class SpecialPerson < Sequel::Model(:person)
  plugin Tombstone::ModelPermissions
end

module Tombstone
  describe ModelPermissions do
    context "dataset" do
      it "defaults to default role" do
        SpecialPerson.permissions.should be_a(Tombstone::Permissions)
        SpecialPerson.permissions.role.should == :default
      end
      
      it "can set and get permissions" do
        perms = Tombstone::Permissions.new(:coordinator)
        SpecialPerson.permissions(perms).permissions.should equal(perms)
      end
      
      it "should clone the dataset when permissions are set" do
        perms = Tombstone::Permissions.new(:coordinator)
        SpecialPerson.permissions(perms)
        SpecialPerson.permissions.should_not equal(perms)
      end
    end
    
    context "instance" do
      it "defaults to default role" do
        sp = SpecialPerson.find
        sp.permissions.should be_a(Tombstone::Permissions)
        sp.permissions.role.should == :default
      end
      
      it "can set and get permissions" do
        perms = Tombstone::Permissions.new(:operator)
        sp = SpecialPerson.find
        sp.permissions(perms).permissions.should equal(perms)
      end
      
      it "inherits permissions from parent dataset" do
        perms = Tombstone::Permissions.new(:coordinator)
        SpecialPerson.permissions(perms).first.permissions.should equal(perms)
      end
    end
  end
end
