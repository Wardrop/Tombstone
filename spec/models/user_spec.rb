require_relative '../spec_helper'

module Tombstone
  describe User do
    it "can retrieve user on primary key" do
      User['tomw'].should_not be_nil
    end
    
    it "provides a Permissions object based on user role" do
      u = User.new
      u.role_permissions.should be_a(Tombstone::Permissions)
      User['tomw'].role_permissions.role.should == :coordinator
    end
    
    it "authenticates users" do
      u = User.new.set(id: LDAP_USER[:username])
      u.authenticate(LDAP_USER[:password]).should == true
    end
    
    it "provides LDAP object" do
      u = User.new.set(id: LDAP_USER[:username])
      u.authenticate(LDAP_USER[:password])
      u.ldap.user_details[:mail][0].index('@trc.qld.gov.au').should > 0
      
    end
    
    it "errors when LDAP object is retrieved before authenticating" do
      expect {
        User.new.set(id: LDAP_USER[:username]).ldap
      }.to raise_error(StandardError)
    end
    
    it "updates permissions object if role changed" do
      u = User['tatej']
      original_role = u.role
      begin
        u.set(role: 'operator').save
        rp = u.role_permissions
        u.role_permissions.can_delete_files?.should == false
        u.set(role: 'coordinator').save
        u.role_permissions.can_delete_files?.should == true
        u.role_permissions.should be_equal(rp)
      ensure
        User['tatej'].set({:role => original_role}).save
      end
    end
    
  end
end
