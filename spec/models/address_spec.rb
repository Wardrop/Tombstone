require_relative '../spec_helper'
require_relative 'models_spec_helper'

module Tombstone
  describe Address do
    
    it "has associated roles through mailing address" do
      address = Address.with_pk(1)
      address.roles_with_residential_address[0].should be_a(Role)
      address.roles_with_residential_address[0].id.should == 3
    end
    
    it "has associated roles through residential address" do
      address = Address.with_pk(2)
      address.roles_with_mailing_address[0].should be_a(Role)
      address.roles_with_mailing_address[0].id.should == 2
    end
    
  end
end
