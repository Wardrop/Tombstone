module Tombstone
  App.controller :find do
    
    get :index do
      @records = Allocation.filter(type: 'reservation').all
      render 'find/index'
    end
    
  end
end