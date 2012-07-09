require_relative '../spec_helper'
require_relative '../../app/lib/search'

module Tombstone
  describe Search do
    it "has defined searchable and sortable fields" do
      Search.searchable.should be_a(Hash)
      Search.searchable.each { |k,v| v.should be_a(Proc) }
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
    
    it "ignores invalid and non-searchable fields" do
      example_search = search.query([{field: :name, operator: ':', value: 'a'}, {field: :raspberry, operator: ':', value: 'a'}])
      example_search.count.should == search.query([{field: :name, operator: ':', value: 'a'}]).count
    end
    
    it "can search and sort fields" do
      record_count = search.query([{field: :name, operator: ':', value: 'a'}], [[:created_at, :desc], [:modified_at, :asc]]).to_a.count
      record_count.should > 0
      record_count.should < model_class.all.count
    end
    
    it "modifies the given array of search terms" do
      terms = [{field: :name, operator: ':', value: 'a'}, {field: :raspberry, operator: ':', value: 'a'}]
      search.query(terms)
      terms.length.should == 1
      terms[0][:field].should == :name
    end
  end
    
  describe AllocationSearch do
    it_behaves_like "a search class"
  end
  
  describe PlaceSearch do
    it_behaves_like "a search class"
  end
end
