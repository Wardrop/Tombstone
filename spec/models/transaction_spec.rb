require_relative '../spec_helper'

module Tombstone
  describe Transaction do
    
    it "is configured correctly" do
      trans = Transaction.with_pk([2, 'interment', 69242])
      trans.should be_a(Transaction)
      trans.receipt_no.should == 69242
    end
    
    it "has an allocation" do
      trans = Transaction.with_pk([2, 'interment', 69242])
      trans.allocation.should be_a(Allocation)
    end
    
  end
end