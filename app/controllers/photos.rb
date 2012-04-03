module Tombstone

  App.controller :photos do

    get :view, :map => "photos/:id/view", :provides => :html do
      @place_id = params[:id].to_i
      @blobs = Blob.filter(:place_id => @place_id).and(:enabled => 1).all
      partial "photos/view"
    end

    get :edit, :map => "photos/:id/edit", :provides => :html do
      @place_id = params[:id].to_i
      @blobs = Blob.filter(:place_id => @place_id).and(:enabled => 1).and(~{:id => session[:deleted_photos]}).or(:id => session[:new_photos]).all
      partial "photos/edit"
    end

    post :add, :map => "photos/:id/add" do
      if params[:file]
        blob = Blob.new(:place_id => params[:id].to_i)
        blob.file = params[:file]
        blob.save(validate:false)
        blob.reload
        session[:new_photos] ||= []
        session[:new_photos].push(blob[:id])
      end
      redirect to(url(:photos_edit, :id => params[:id].to_i))
    end

    get :delete, :map => "photos/:place_id/:id/delete", :provides => :html do
      session[:deleted_photos] ||= []
      session[:deleted_photos].push(params[:id].to_i)
      session[:new_photos].delete(params[:id].to_i)
      redirect to(url(:photos_edit, :id => params[:place_id].to_i))
    end
  end
end

