require_relative '../spec_helper'

module Tombstone
  
  describe BaseModel do
    it "can ignore invalid columns during set" do
      (Allocation < BaseModel).should be_true
      base = Allocation.new.set_valid_only({invalid_field: 'should be ignored', comments: 'some comment'})
      base.comments.should == 'some comment'
      base[:invalid_field].should be_nil
    end
  end

end
