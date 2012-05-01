module Tombstone
  App.controller :person do

    get :all, :provides => :json do
      filter_hash = params.reject{ |k,v| !v || v.empty? }.symbolize_keys!
      json_response Person.filter(filter_hash)
    end

    get :contacts, :provides => :json do
      json_response Person.select_all(:contact).distinct.filter(:person__id => params[:person_id]).
        join(:role, :role__person_id => :person__id).
        join(:contact, :contact__id => [:role__residential_contact_id, :role__mailing_contact_id])
        .naked.all
    end
    
    get :validate, :provides => :json do
      person = Person.new.set_valid_only(params)
      json_response(valid: person.valid?, errors: person.errors)
    end
    
    get :index, :with => :id, :provides => :json do
      json_response Person.filter(:id => params[:id])
    end
    
  end
end