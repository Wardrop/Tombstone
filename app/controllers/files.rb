require 'stringio'

module Tombstone
  Root.controller '/files' do

    get "/:id" do |id|
      response['Cache-Control'] = 'max-age=3600, public'
      file = Blob.with_pk(id.to_i)
      if file
        response['Last-Modified'] = (file.modified_at || file.created_at).rfc822
        disposition = (file.content_type =~ /^image\//) ? 'inline' : 'attachment'
        response['Content-Disposition'] = "#{disposition}; filename=#{file.name}"
        response['Content-Type'] = file.content_type
        file.data
      else
        halt 404
      end
    end

    get "/:id/thumbnail" do |id|
      response['Cache-Control'] = 'max-age=3600, public'
      file = Blob.with_pk(id.to_i)
      if file
        response['Last-Modified'] = (file.modified_at || file.created_at).rfc822
        response.headers.merge!('Content-Disposition' => "inline; filename=#{file.name}", 'Content-Type' => 'image')
        file.thumbnail || open('../public/images/generic_file.png').read
      else
        halt 404
      end
    end

    # Action must provide text content-type or else IE9 prompts for download, regardless of the content-disposition.
    post "/:place_id" do |place_id|
      response['Content-Type'] = "text/plain"
      upload = request.POST['file']
      if upload
        file = Blob.new(:place_id => place_id.to_i)
        thumbnail = nil
        dimensions = "#{Blob.thumbnail_dimensions[:width]}x#{Blob.thumbnail_dimensions[:height]}"
        begin
          image = MiniMagick::Image.read(upload[:tempfile])
          image.format('jpg') unless upload[:type] =~ /(jpe?g|gif|png)$/
          image.combine_options do |c|
            c.colorspace('sRGB')
            c.resize("#{dimensions}^")
            c.gravity('center')
            c.crop("#{dimensions}+0+0")
          end
          thumbnail = image.write(StringIO.new).string
        rescue MiniMagick::Error, MiniMagick::Invalid => e
          puts "DEBUG: Could not process file as image: #{e.message}"
        end
        file.set(
          data: upload[:tempfile].rewind && upload[:tempfile].read,
          size: upload[:tempfile].size,
          name: upload[:filename],
          content_type: upload[:type],
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

    delete "/:id", media_type: "application/json" do |id|
      file = Blob.with_pk(id.to_i)
      file ? file.destroy : halt(404)
      json_response
    end
  end
end
