module Tombstone
  App.controller :place do
    
    get :index do
      @place = Place.with_pk(params['place_id']) if params['place_id']
      render 'place/new'
    end

    get :index, :with => :id, :provides => :json do
      Place.with_pk(params[:id]).values.to_json
    end
    
    # Valid ranges: Row [A-Z], Plot [1-49]a, Row [A-ZZ], Plot[001-150]
    # Zero-prefixes are decided at a global level.
    post :index, :provides => :json do
      place = Place.new.set_valid_only(params)
      if place.valid?
        parsed = parse_place_name(params['name'])
        if parsed.nil?
          place.save
        elsif Array === parsed
          Place.dataset.multi_insert(parsed.map { |v| params.merge({'name' => v}) })
        else
          place.errors.add(:name, parsed)
        end
      end
      {success: place.errors.length < 1, form_errors: place.errors}.to_json
    end
    
    put :index, :with => :id, :provides => :json do
      place = Place.with_pk(params[:id])
      halt 404, "Place with ID ##{params[:id]} does not exist." unless place
      place.set_valid_only(params)
      if place.valid?
        place.save
      end
      {success: place.errors.length < 1, form_errors: place.errors}.to_json
    end
    
    delete :index, :with => :id, :provides => :json do
      # Make sure the place is not associated with any allocations (inc. deleted)
      # TODO: Handle the case where a place has associated images.
      halt 500, {success: false, form_errors: 'Sorry, try again'}.to_json
    end

    get :next_available, :with => :parent_id, :provides => :json do
      place = Place.with_pk(params[:parent_id])
      halt 404, "Place with ID ##{params[:parent_id]} does not exist." unless place
      next_available = place.next_available
      if next_available
        ancestors = next_available.ancestors(false, params[:parent_id])
        chain = ancestors.reverse.push(next_available)
        chain.reduce({}) { |memo, place|
          memo[place.id] = place.siblings.with_child_count.available_only.naked.all
          memo
        }.to_json
      else
        nil.to_json
      end
    end
    
    get :children, :map => %r{/place/([0-9]+)/children(/[^/]+)?}, :provides => :json do |id, filter|
      filter = filter[1..-1] if filter
      p filter
      id = (id.to_i < 1) ? nil : id.to_i
      places = Place.filter(:parent_id => id)
      if filter
        case filter
        when 'available'
          places = places.available_only
        when 'all'
        else
          halt 404
        end
      end
      places.order(:name).with_child_count.naked.all.to_json
    end
    
    # get :children, :with => [:parent_id, :option], :provides => :json do
    #   children = Place.filter(:parent_id => params[:parent_id]).order(:name).with_child_count
    #   case params[:option]
    #   when 'available'
    #     children.available_only
    #   end
    #   Place.filter(:parent_id => params[:parent_id]).order(:name).with_child_count.available_only.naked.all.to_json
    # end
    
    get :ancestors, :with => :id, :provides => :json do
      place = Place.with_pk(params[:id])
      halt 404, "Place with ID ##{params[:id]} does not exist." unless place
      chain = place.ancestors(!!params['include_self']).reduce([]) do |memo, anc|
        memo << Place.filter(:parent_id => anc.parent_id).naked.all
      end
      chain.to_json
    end
    
  end
end