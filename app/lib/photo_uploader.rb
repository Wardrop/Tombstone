module Tombstone

  class PhotoUploader < CarrierWave::Uploader::Base
    include CarrierWave::MiniMagick
    include CarrierWave::MimeTypes
    
    def self.dimensions
      {thumbnail: [256,160], preview: [800,500]}
    end
    
    storage :file
    process :set_content_type
    version :thumbnail do
      process(resize_to_fill: dimensions[:thumbnail])
    end

    def store_dir
      "uploads/place/#{model.place_id}"
    end

    def get_exif(name)
      manipulate! do |img|
        return img["EXIF:" + name]
      end
    end
    
    def filename
      without_ext = File.basename(@filename, File.extname(@filename))
      @name ||= "#{without_ext}_#{random_token}.#{file.extension}" if original_filename.present?
    end
  
  protected
    
    def random_token
      var = :"@#{mounted_as}_random_token"
      model.instance_variable_get(var) or
        model.instance_variable_set(var, SecureRandom.base64(9).gsub('/', '_').gsub('+', '-'))
    end

  end

end
