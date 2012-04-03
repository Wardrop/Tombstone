module Tombstone
  App.controller :person do

    get :all, :provides => :json do
      filter_hash = params.reject{ |k,v| !v || v.empty? }.symbolize_keys!
      p filter_hash
      Person.filter(filter_hash).naked.all.to_json
    end

    get :contacts, :provides => :json do
      Person.select_all(:contact).distinct.filter(:person__id => params[:person_id]).
        join(:role, :role__person_id => :person__id).
        join(:contact, :contact__id => [:role__residential_contact_id, :role__mailing_contact_id])
        .naked.all.to_json
    end
    
    get :validate, :provides => :json do
      person = Person.new(params.select { |k,v| Person.columns.include?(k.to_sym) && !v.blank? })
      {valid: person.valid?, errors: person.errors}.to_json
    end
    
    get :index, :with => :id, :provides => :json do
      Person.filter(:id => params[:id]).naked.all.to_json
    end
    
  end
end