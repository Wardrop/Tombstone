require_relative '../spec_helper'

class SpecialPerson < Sequel::Model(:person)
  plugin Tombstone::ModelPermissions
end

module Tombstone
  describe ModelPermissions do
    context "dataset" do
      it "has an empty Permissions object by default" do
        SpecialPerson.permissions.should be_a(Tombstone::Permissions)
        SpecialPerson.permissions.to_hash.should be_empty
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
      it "has an empty Permissions object by default" do
        sp = SpecialPerson.find
        sp.permissions.should be_a(Tombstone::Permissions)
        sp.permissions.to_hash.should be_empty
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
