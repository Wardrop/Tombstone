module Tombstone
  App.controller :find do
    
    get :index do
      @records = Allocation.filter.all
      render 'find/index'
    end
    
  end
end