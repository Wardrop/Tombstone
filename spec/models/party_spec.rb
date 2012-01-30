require_relative '../spec_helper'
require_relative 'models_spec_helper'

module Tombstone
  describe Party do
    
    it "is associated with many roles" do
      party = Party.with_pk(1)
      party.roles[0].should be_a(Role)
      party.roles[0].id.should == 1
      party.roles[1].id.should == 4
    end
    
  end
end
