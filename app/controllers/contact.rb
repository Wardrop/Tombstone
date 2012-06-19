module Tombstone
  App.controller :contact do

    get :index, :with => :id, :provides => :json do
      json_response Contact.filter(:id => params[:id]).naked.all
    end
    
    get :all, :provides => :json do
      filter_hash = params.reject{ |k,v| !v || v.empty? }.symbolize_keys!
      json_response Contact.filter(filter_hash).naked.all
    end
    
    get :validate, :provides => :json do
      contact = Contact.new.set_valid_only(params)
      json_response(valid: contact.valid?, errors: contact.errors)
    end
    
  end
end