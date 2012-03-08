module Tombstone
  App.controller :place do
    
    get :children, :with => :parent_id, :provides => :json do
      Place.filter(:parent_id => params[:parent_id]).order(:name).available_only.naked.all.to_json
    end
    
    get :next_available, :with => :parent_id, :provides => :json do
      place = Place.with_pk(params[:parent_id])
      halt 404, "Place with ID ##{params[:parent_id]} does not exist." unless place
      next_available = place.next_available
      ancestors = next_available.ancestors(false, params[:parent_id])
      chain = ancestors.reverse.push(next_available)
      
      
      chain.reduce([]) { |memo, place|
        values = place.values
        if chain.last == place
          values[:siblings] = place.siblings.available_only.naked.all
          p values[:siblings]
        else
          values[:siblings] = place.siblings.naked.all
        end
        memo << values
      }.to_json
    end
    
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