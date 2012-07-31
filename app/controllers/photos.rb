module Tombstone

  App.controller :photos do

    get :view, :map => "photos/:place_id" do
      photos = Photo.filter(:place_id => params[:place_id].to_i).and(:enabled => 1).all
      partial "photos/view", :locals => {photos: photos}
    end
    
    # get :view, :map => "photos/:id/view", :provides => :html do
    #   @place_id = params[:id].to_i
    #   @blobs = Blob.filter(:place_id => @place_id).and(:enabled => 1).all
    #   partial "photos/view"
    # end
    
    post :new, :map => "photos/:place_id", :provides => :html do
      p request
      if params[:file]
        photo = Photo.new(:place_id => params[:place_id].to_i)
        photo.data = params[:file][:tmp_file].read
        # photo.file = params[:file]
        if photo.valid?
          photo.save
        end
        session['new_photos'] ||= []
        session['new_photos'] << photo[:id]
      end
      if photo.errors.empty?
        photo.to_json(:include => [:thumbnail, :thumbnail_dimensions])
      else
        {errors: photo.errors}.to_json
      end
      # redirect to(url(:photos_edit, :id => params[:place_id].to_i))
    end

    # puts :edit, :map => "photos/:place_id/:id", :provides => :json do
    #   photos = Photo.filter(:place_id => params[:place_id].to_i).and(:enabled => 1).exclude(:id => session[:deleted_photos]).or(:id => session['new_photos']).all
    #   partial "photos/edit", :locals => {photos: photos}
    #   json_response
    # end

    delete :delete, :map => "photos/:place_id/:id", :provides => :json do
      session['deleted_photos'] ||= []
      session['deleted_photos'].push(params[:id].to_i)
      session['new_photos'].delete(params[:id].to_i)
      json_response
      # redirect to(url(:photos_edit, :id => params[:place_id].to_i))
    end
  end
end


