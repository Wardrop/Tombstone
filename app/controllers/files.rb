require 'stringio'

module Tombstone

  App.controller :files do
    
    get :view, :map => "files/:id" do
      file = Blob.with_pk(params[:id].to_i)
      if file && file.enabled
        disposition = (file.content_type =~ /^image\//) ? 'inline' : 'attachment'
        response.headers.merge!('Content-Disposition' => "#{disposition}; filename=#{file.name}", 'Content-Type' => file.content_type)
        file.data
      else
        halt 404
      end
    end
    
    get :thumbnail, :map => "files/:id/thumbnail" do
      file = Blob.with_pk(params[:id].to_i)
      if file && file.enabled
        response.headers.merge!('Content-Disposition' => "inline; filename=#{file.name}", 'Content-Type' => 'image')
        file.thumbnail
      else
        halt 404
      end
    end
    
    get :for_place, :map => "files/for_place/:place_id" do
      files = Blob.filter(:place_id => params[:place_id].to_i).and(:enabled => 1).all
      partial "files/view", :locals => {files: files}
    end
    
    post :new, :map => "files/:place_id", :provides => :html do
      if params[:file]
        file = Blob.new(:place_id => params[:place_id].to_i)
        thumbnail = nil
        if params[:file][:type] =~ /^image\//
          dimensions = "#{Blob.thumbnail_dimensions[:width]}x#{Blob.thumbnail_dimensions[:height]}"
          image = MiniMagick::Image.read(params[:file][:tempfile])
          image.resize("#{dimensions}^")
          image.gravity('center')
          image.crop("#{dimensions}+0+0")
          thumbnail = image.write(StringIO.new)
        end
        file.set(
          data: params[:file][:tempfile].rewind && params[:file][:tempfile].read,
          size: params[:file][:tempfile].size,
          name: params[:file][:filename],
          content_type: params[:file][:type],
          thumbnail: thumbnail.string
        )
        if file.valid?
          file.save
        end
        session['new_files'] ||= []
        session['new_files'] << file[:id]
      end
      if file.errors.empty?
        file.to_json(:include => [:thumbnail_dimensions], :except => [:data, :thumbnail])
      else
        {errors: file.errors}.to_json
      end
    end

    delete :delete, :map => "files/:id", :provides => :json do
      session['deleted_files'] ||= []
      session['deleted_files'].push(params[:id].to_i)
      session['new_files'].delete(params[:id].to_i)
      json_response
    end
  end
end


