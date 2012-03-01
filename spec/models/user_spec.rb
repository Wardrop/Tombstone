require_relative '../spec_helper'

module Tombstone
  describe User do
    it "can retrieve user on primary key" do
      User['tomw'].name.should == 'Tom Wardrop'
    end
    
    it "includes ModelPermissions plugin" do
      User.plugins.should include(Tombstone::ModelPermissions)
    end
    
    it "provides a Permissions object based on user role" do
      u = User.new
      u.role_permissions.should be_a(Tombstone::Permissions)
      User['tomw'].role_permissions.role.should == :supervisor
    end
    
    context do
      it "updates permissions object if role changed" do
        u = User['tatej']
        u.role_permissions.can_delete_photos?.should == false
        u.role = 'supervisor'
        u.save
        u.role_permissions.can_delete_photos?.should == true
      end
      
      after(:all) do
        User['tatej'].set({:role => 'operator'}).save
      end
    end
    
  end
end
