require_relative '../spec_helper'
require_relative '../../app/lib/search'

module Tombstone
  describe Search do
    it "has defined searchable and sortable fields" do
      Search.searchable.should be_a(Hash)
      Search.searchable.each { |k,v| v.should be_a(Hash) }
      Search.sortable.should be_a(Hash)
    end
  end
  
  shared_examples "a search class" do
    let(:search) { described_class.new }
    let(:model_class) { search.class::MODEL }
    
    it "should return all records if no conditions given" do
      search.query.count.should == model_class.all.count
    end
    
    it "should return a Sequel dataset" do
      search.query.should be_a(Sequel::Dataset)
    end
    
    it "should return complete model objects" do
      model = search.query.first
      model.should be_a(model_class)
      model.should == model_class.filter(model.pk_hash).first
    end
    
    it "can search fields" do
      search.query(:email => 'littlesamurai@myfantasy.com').count.should >= 1
      search.query(:email => 'littlesamurai@myfantasy.com', :given_name => 'Phillip').count.should >= 1
    end
    
    it "ignores invalid and non-searchable fields" do
      search.query(:primary_phone => '07 4959 39493', :raspberry => 'Yes Please!').count.should == model_class.all.count
      search.query(
        :primary_phone => '07 4959 39493',
        :email => 'littlesamurai@myfantasy.com'
      ).count.should == search.query(:email => 'littlesamurai@myfantasy.com').count
    end
    
    # We have no easy way to verify the sort behaviour, so we just ensure that sorting doesn't alter the number of results returned.
    it "can sort fields" do
      search.query({}, :surname, :desc).to_a.count.should == model_class.all.count
    end
    
    it "can sort multiple fields" do
      search.query({}, :surname, :desc, :given_name, :asc).to_a.count.should == model_class.all.count
    end
    
    it "can sort and search at the same time" do
      search.query(
        {:email => 'littlesamurai@myfantasy.com', :given_name => 'Phillip'},
        :surname, :desc, :given_name, :asc
      ).to_a.count.should >= 1
    end
  end
    
  describe AllocationSearch do
    it_behaves_like "a search class"
  end
  
  describe PersonSearch do
    it_behaves_like "a search class"
  end
end
