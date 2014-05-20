require 'stringio'

module Tombstone

  App.controller :files do
    
    get :view, :map => "files/:id" do
      file = Blob.with_pk(params[:id].to_i)
      if file
        disposition = (file.content_type =~ /^image\//) ? 'inline' : 'attachment'
        response.headers.merge!(
          'Content-Disposition' => "#{disposition}; filename=#{file.name}",
          'Content-Type' => file.content_type,
          'Content-Length' => file.data.length
        )
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
        retval = file.thumbnail || open('public/images/generic_file.png').read
        response.headers.merge!(
          'Content-Disposition' => "inline; filename=#{file.name}",
          'Content-Type' => 'image',
          'Content-Length' => retval.length
        )
        retval
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
        begin
          image = MiniMagick::Image.read(params[:file][:tempfile])
          image.combine_options do |c|
            c.format('jpg') unless params[:file][:type] =~ /(jpe?g|gif|png)$/
            c.colorspace('RGB')
            c.resize("#{dimensions}^")
            c.gravity('center')
            c.crop("#{dimensions}+0+0")
          end
          thumbnail = image.write(StringIO.new).string
        rescue MiniMagick::Error, MiniMagick::Invalid => e
          puts "DEBUG: Could not process file as image: #{e.message}"
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
        if file.errors.empty?
          file.to_json(:include => [:thumbnail_dimensions], :except => [:data, :thumbnail])
        else
          {errors: file.errors}.to_json
        end
      else
        {errors: 'No file was uploaded.'}.to_json
      end
    end

    delete :delete, :map => "files/:id", :provides => :json do
      file = Blob.with_pk(params[:id])
      file ? file.destroy : halt(404)
      json_response
    end
  end
end


