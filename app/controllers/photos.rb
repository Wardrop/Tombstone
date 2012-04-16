module Tombstone

  App.controller :photos do

    get :view, :map => "photos/:place_id" do
      @photos = Photo.filter(:place_id => params[:place_id].to_i).and(:enabled => 1).all
      partial "photos/view"
    end
    
    # get :view, :map => "photos/:id/view", :provides => :html do
    #   @place_id = params[:id].to_i
    #   @blobs = Blob.filter(:place_id => @place_id).and(:enabled => 1).all
    #   partial "photos/view"
    # end

    get :edit, :map => "photos/:place_id/edit" do
      photos = Photo.filter(:place_id => params[:place_id].to_i).and(:enabled => 1).exclude(:id => session[:deleted_photos]).or(:id => session[:new_photos]).all
      partial "photos/edit", :locals => {photos: photos}
    end

    post :add, :map => "photos/:place_id" do
      if params[:file]
        photo = Photo.new(:place_id => params[:place_id].to_i)
        photo.file = params[:file]
        photo.save(validate:false)
        session[:new_photos] ||= []
        session[:new_photos] << photo[:id]
      end
      ""
      # redirect to(url(:photos_edit, :id => params[:place_id].to_i))
    end

    get :delete, :map => "photos/:place_id/:id/delete", :provides => :html do
      session[:deleted_photos] ||= []
      session[:deleted_photos].push(params[:id].to_i)
      session[:new_photos].delete(params[:id].to_i)
      ""
      # redirect to(url(:photos_edit, :id => params[:place_id].to_i))
    end
  end
end


