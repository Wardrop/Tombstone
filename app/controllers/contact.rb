module Tombstone
  Root.controller '/contact' do

    get '/all', media_type: 'application/json' do
      filter_hash = request.GET.reject{ |k,v| !v || v.empty? }.symbolize_keys!
      json_response Contact.filter(filter_hash).naked.all
    end
    
    get '/validate', media_type: 'application/json' do
      contact = Contact.new.set_valid_only(request.GET)
      json_response(valid: contact.valid?, errors: contact.errors)
    end
    
    get '/:id', media_type: 'application/json' do |id|
      json_response Contact.filter(:id => id).naked.all
    end
    
  end
end