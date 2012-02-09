require_relative '../spec_helper'
require_relative 'models_spec_helper'

module Tombstone
  describe Person do
    
    it "is configured correctly" do
      person = Person.with_pk(1)
      person.given_name.should == 'Roger'
    end
    
    it "is associated with many roles" do
      person = Person.with_pk(1)
      person.roles[0].should be_a(Role)
      person.roles[0].id.should == 1
      person.roles[1].id.should == 4
    end
    
  end
end
