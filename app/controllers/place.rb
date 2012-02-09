module Tombstone
  App.controller :place do
    
    get :children, :with => :parent_id, :provides => :json do
      Place.with_child_count.filter(:parent_id => params[:parent_id]).order(:name).naked.all.to_json
    end
    
    get :next_available, :with => :parent_id, :provides => :json do
      next_available = Place.with_pk(params[:parent_id]).next_available
      ancestors = next_available.ancestors(params[:parent_id])
      chain = ancestors.reverse.push(next_available)
      
      result = []
      chain.each do |p|
        place = p.values
        place[:siblings] = Place.with_child_count.filter(:parent_id => place[:parent_id]).order(:id).naked.all
        result << place
      end
      result.to_json
    end
  end
end