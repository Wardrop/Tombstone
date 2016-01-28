module Tombstone
  Root.controller '/person' do

    get '/all', media_type: 'application/json' do
      filter_hash = request.GET.reject{ |k,v| !v || v.empty? }.symbolize_keys!
      Person.datetime_columns
      json_response Person.filter(filter_hash)
    end
    
    get '/search', media_type: 'application/json' do
      filtered_hash = request.GET.reject{ |k,v| !v || v.empty? }.symbolize_keys!
      filtered_hash = Person.prepare_values(filtered_hash)
      filtered_hash[:date_of_birth] = filtered_hash[:date_of_birth].strftime('%d/%m/%Y') if filtered_hash[:date_of_birth]
      filtered_hash[:date_of_death] = filtered_hash[:date_of_death].strftime('%d/%m/%Y') if filtered_hash[:date_of_death]
      json_response Person.search(filtered_hash, 50)
    end

    get '/contacts', media_type: 'application/json' do
      json_response Person.select_all(:contact).distinct.filter(:person__id => request.GET[:person_id]).
        join(:role, :role__person_id => :person__id).
        join(:contact, :contact__id => [:role__residential_contact_id, :role__mailing_contact_id]).
        naked.all
    end
    
    get '/validate', media_type: 'application/json' do
      person = Person.new.set_valid_only(request.GET)
      json_response(valid: person.valid?, errors: person.errors)
    end
    
    get '/:id', media_type: 'application/json' do |id|
      json_response Person.filter(:id => id)
    end
    
  end
end