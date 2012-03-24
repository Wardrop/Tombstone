module Tombstone
  App.controller :photos do

    get :view, :map => "photos/:id/", :provides => :html do
      @place_id = params[:id].to_i
      @blobs = Blob.filter(:place_id => @place_id).all
      partial "photos/view"
    end

    post :add, :map => "photos/:id/add" do
      blob = Blob.new(:place_id => params[:id].to_i)
      blob.file = params[:blob]
      blob.save(validate:false)
      redirect to(url(:photos_view, :id => params[:id].to_i))
    end

  end
end


