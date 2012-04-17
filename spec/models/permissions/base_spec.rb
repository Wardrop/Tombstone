require_relative '../../spec_helper'

module Tombstone

  describe ModelPermissions::BaseModel do
    
    before :all do
      BaseModel.send(:include, ModelPermissions::BaseModel)
    end
    
    it "adds class permissions accessor when included" do
      BaseModel.respond_to? :permissions
      BaseModel.respond_to? :permissions=
    end
    
    it "defaults to default permissions object" do
      BaseModel.permissions.should be_a(Permissions)
      BaseModel.permissions.role.should == :default
    end
    
    it "can take a permissions object" do
      coordinator = Permissions.new(:coordinator)
      BaseModel.permissions = coordinator
      BaseModel.permissions.should == coordinator
      BaseModel.permissions = nil
      BaseModel.permissions.role.should == :default
    end
    
  end
end