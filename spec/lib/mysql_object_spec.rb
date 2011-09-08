require_relative '../../lib/mysql_object'
require_relative '../spec_helper'

module Tombstone
  class User
    include MySQLObject
    
    fields :id, :name, :email, :age
  end
  
  class MajorCity
    include MySQLObject
  end
  
  describe MySQLObject do
    context "general" do
      it "returns a Mysql2 client object" do
        MySQLObject.client.should be_a(Mysql2::Client)
      end
      
      it "resets the connection when connection options are changed" do
        original = MySQLObject.client
        MySQLObject.connection_options = {}
        MySQLObject.client.should_not == original
      end
      
      it "respects connection options" do
        MySQLObject.connection_options = {:host => 'localhost', :username => 'invalid user'}
        expect {
          MySQLObject.client
        }.to raise_error(Mysql2::Error, "Access denied for user 'invalid user'@'localhost' (using password: NO)")
        MySQLObject.connection_options = {}
      end
    end
    
    context "class" do
      it "uses the client object from up the chain" do
        User.client.should == MySQLObject.client
      end
      
      it "overrides the client object when connection options are given" do
        User.connection_options = {}
        User.client.should_not == MySQLObject.client
      end
      
      it "resets the client when connection options are changed" do
        original = User.client
        User.connection_options = {}
        User.client.should_not == original
      end
      
      it "defaults to the class name as the table name" do
        User.table.should == 'user'
        MajorCity.table.should == 'major_city'
      end
      
      it "can get, set and reset the table name" do
        original = User.table
        User.table('things')
        User.table.should == 'things'
        original.should == User.table(nil)
        original.should == User.table
      end
      
      it "can load a user on a set of criteria" do
        User.connection_options = SPEC_CONFIG[:db]
        User.client.query("INSERT INTO user VALUES (null, 'John Tomson', 'john@tomson.com', 46)")
        john = User.load({:name => 'John Tomson'})
        john.to_hash.values[1..-1].should == ['John Tomson', 'john@tomson.com', 46]
      end
      
      it "returns false when no records match" do
        User.connection_options = SPEC_CONFIG[:db]
        User.load({:name => 'Fletch Adams'}).should == false
      end
      
      it "can get and set fields" do
        MajorCity.fields.should be_empty
        MajorCity.fields :name, 'age'
        MajorCity.fields.should == [:name, 'age'].to_set
        MajorCity.fields(nil)
        MajorCity.fields.should == [].to_set
      end
      
      it "regards symbol fields as key fields" do
        MajorCity.fields :name, :email, 'age'
        MajorCity.key_fields.should == ['name', 'email']
      end
    end
    
    context "instance" do
      it "uses the client object from up the chain" do
        User.new.client.should == User.client
      end
      
      it "overrides the client object when connection options are provided" do
        User.new({}, {}).client.should_not == User.client
      end
      
      it "can get and set field values" do
        john = User.new
        john[:name] = 'John Tomson'
        john['email'] = 'john@tomson.com'
        john['name'].should == 'John Tomson'
        john[:email].should == 'john@tomson.com'
      end
      
      it "takes an initial set of values" do
        john = User.new(:name => 'John Tomson', 'email' => 'john@tomson.com', :age => 46)
        john['name'].should == 'John Tomson'
        john[:email].should == 'john@tomson.com'
      end
      
      it "can set multiple fields at once" do
        john = User.new
        john.set :name => 'John', 'email' => 'john@tomson.com'
        john['name'].should == 'John'
        john['email'].should == 'john@tomson.com'
      end
      
      it "raises an error when an invalid field is set" do
        john = User.new
        expect {
          john.set :bleh => 'Blah', 'email' => 'john@tomson.com'
        }.to raise_error
        expect {
          john[:bleh] = 'Blah'
        }.to raise_error
        expect {
          User.new :bleh => 'Blah', 'email' => 'john@tomson.com'
        }.to raise_error
      end
      
      it "returns a hash of values" do
        john = User.new :name => 'John', 'email' => 'john@tomson.com'
        john.to_hash.should == {'name' => 'John', 'email' => 'john@tomson.com'}
      end
      
      it "validates as true by default" do
        User.new.validate.should == true
      end
      
      it "by default, inserts on save if record doesn't exist" do
        User.new(:name => 'Roger', :email => 'roger@trucksandstuff.com').save
        User.client.query("")
      end
    end
  end
end