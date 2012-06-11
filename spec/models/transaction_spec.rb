require_relative '../spec_helper'

module Tombstone
  describe Transaction do
    
    it "is configured correctly" do
      trans = Transaction.with_pk([3, '69242a'])
      trans.should be_a(Transaction)
      trans.receipt_no.should == '69242a'
    end
    
    it "has an allocation" do
      trans = Transaction.with_pk([3, '69242a'])
      trans.allocation.should be_a(Allocation)
    end
    
  end
end