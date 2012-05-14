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
      "uploads/place/#{model.place_id}/photos"
    end

    def get_exif(name)
      manipulate! do |img|
        return img["EXIF:" + name]
      end
    end

  end

end
