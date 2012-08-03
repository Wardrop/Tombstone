require 'stringio'

module Tombstone

  App.controller :files do
    
    get :view, :map => "files/:id" do
      file = Blob.with_pk(params[:id].to_i)
      if file
        disposition = (file.content_type =~ /^image\//) ? 'inline' : 'attachment'
        response.headers.merge!('Content-Disposition' => "#{disposition}; filename=#{file.name}", 'Content-Type' => file.content_type)
        file.data
      else
        halt 404
      end
    end
    
    get :thumbnail, :map => "files/:id/thumbnail" do
      expires 3600, :public
      file = Blob.with_pk(params[:id].to_i)
      if file
        last_modified(file.modified_at || file.created_at)
        response.headers.merge!('Content-Disposition' => "inline; filename=#{file.name}", 'Content-Type' => 'image')
        file.thumbnail || open('public/images/generic_file.png').read
      else
        halt 404
      end
    end
    
    # get :for_place, :map => "files/for_place/:place_id" do
    #   files = Blob.filter(:place_id => params[:place_id].to_i).and(:enabled => 1).all
    #   partial "files/view", :locals => {files: files}
    # end
    
    # Action must provide text content-type or else IE9 prompts for download, regardless of the content-disposition.
    post :new, :map => "files/:place_id", :provides => :text do
      if params[:file]
        file = Blob.new(:place_id => params[:place_id].to_i)
        thumbnail = nil
        dimensions = "#{Blob.thumbnail_dimensions[:width]}x#{Blob.thumbnail_dimensions[:height]}"
        p params[:file][:type]
        begin
          image = MiniMagick::Image.read(params[:file][:tempfile])
          image.format('jpg') unless params[:file][:type] =~ /(jpe?g|gif|png)$/
          image.colorspace('RGB')
          image.resize("#{dimensions}^")
          image.gravity('center')
          image.crop("#{dimensions}+0+0")
          thumbnail = image.write(StringIO.new).string
        rescue MiniMagick::Error, MiniMagick::Invalid => e
          puts "Could process file as image: #{e.message}"
        end
        file.set(
          data: params[:file][:tempfile].rewind && params[:file][:tempfile].read,
          size: params[:file][:tempfile].size,
          name: params[:file][:filename],
          content_type: params[:file][:type],
          thumbnail: thumbnail
        )
        if file.valid?
          file.save
        end
      end
      if file.errors.empty?
        file.to_json(:include => [:thumbnail_dimensions], :except => [:data, :thumbnail])
      else
        {errors: file.errors}.to_json
      end
    end

    delete :delete, :map => "files/:id", :provides => :json do
      file = Blob.with_pk(params[:id])
      file ? file.destroy : halt(404)
      json_response
    end
  end
end


