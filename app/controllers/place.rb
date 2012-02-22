module Tombstone
  App.controller :place do
    
    get :children, :with => :parent_id, :provides => :json do
      Place.filter(:parent_id => params[:parent_id]).order(:name).naked.all.to_json
    end
    
    get :next_available, :with => :parent_id, :provides => :json do
      place = Place.with_pk(params[:parent_id])
      halt 404, "Place with ID ##{params[:parent_id]} does not exist." unless place
      next_available = place.next_available
      ancestors = next_available.ancestors(params[:parent_id])
      chain = ancestors.reverse.push(next_available)

      chain.reduce([]) { |memo, place|
        place = place.values
        place[:siblings] = Place.filter(:parent_id => place[:parent_id]).order(:id).naked.all
        memo << place
      }.to_json
    end
    
    get :ancestors, :with => :id, :provides => :json do
      place = Place.with_pk(params[:id])
      halt 404, "Place with ID ##{params[:id]} does not exist." unless place
      chain = place.ancestors(0, !!params['include_self']).reduce([]) do |memo, anc|
        memo << Place.filter(:parent_id => anc.parent_id).naked.all
      end
      chain.to_json
    end
  end
end