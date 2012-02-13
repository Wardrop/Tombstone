module Tombstone
  App.controller :contact do

    get :all, :provides => :json do
      filter_hash = params.reject{ |k,v| !v || v.empty? }.symbolize_keys!
      Contact.filter(filter_hash).naked.all.to_json
    end
    
    get :validate, :provides => :json do
      contact = Contact.new(params)
      {valid: contact.valid?, errors: contact.errors}.to_json
    end
    
    get :index, :with => :id, :provides => :json do
      Contact.filter(:id => params[:id]).naked.all.to_json
    end
    
  end
end