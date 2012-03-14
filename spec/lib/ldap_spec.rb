require_relative '../spec_helper'
require_relative '../../app/lib/ldap'

module Tombstone
  describe LDAP do
    before :all do
      @username = LDAP_USER[:username]
      @password = LDAP_USER[:password]
    end
    
    context 'class' do
      before :all do
        @orig_servers = LDAP.servers
      end
      before :each do
        LDAP.servers = ['server1', 'server2:5000', 'server3']
      end
      after :all do
        LDAP.servers = @orig_servers
      end
      
      it "rotates between servers" do
        LDAP.server[0].should == 'server1'
        LDAP.server[0].should == 'server2'
        LDAP.server[0].should == 'server3'
        LDAP.server[0].should == 'server1'
      end
      
      it "returns servers as host/port pairs" do
        LDAP.server.should be_a(Array)
        LDAP.server.length.should == 2
        LDAP.server[1].should be_a(Integer)
        LDAP.server[1].should > 0
      end
      
      it "defaults ports in an intelligent manner" do
        LDAP.use_ssl = false
        LDAP.server[1].should == 389
        LDAP.server[1].should == 5000
        LDAP.use_ssl = true
        LDAP.server[1].should == 636
      end
    end
    
    context 'instance' do
      it "requires a username and password on instantiation" do
        LDAP.new(@username, @password).should be_a(LDAP)
        expect {
           LDAP.new(@username, '')
        }.to raise_error(StandardError)
      end
      
      it "can authenticate using credentials" do
        ldap = LDAP.new(@username, @password)
        ldap.authenticate.should == true
        ldap.authenticated?.should == true
        LDAP.new('bad user', @password).authenticate.should == false
        # Note, we do not include a test for wrong password as that has the potential to lock-out the LDAP account.
      end
      
      context "server cycling" do
        before :all do
          @original_servers = LDAP.servers
        end
        after :each do
          LDAP.servers = @original_servers
        end
        
        it "cycles through servers on failure" do
          LDAP.servers = ['localhost', 'server2:5000', LDAP.servers[0]]
          LDAP.new(@username, @password).authenticate.should == true
        end
      
        it "raises error on server failure" do
          LDAP.servers = ['localhost', 'server2:5000']
          expect {
            LDAP.new(@username, @password).authenticate
          }.to raise_error(StandardError)
        end
      
        # Regression test
        it "re-authenticates on cycled servers" do
          LDAP.servers = ['localhost', LDAP.servers[0]]
          LDAP.new('blah', 'bleh').authenticate.should == false
        end
      end
      
      it "can get the users details" do
        details = LDAP.new(@username, @password).user_details
        details.should be_a(Net::LDAP::Entry)
        details[:sAMAccountName][0].should == @username
      end
    end
    
  end
end