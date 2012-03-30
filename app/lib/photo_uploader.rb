module Tombstone

  class PhotoUploader < CarrierWave::Uploader::Base
    include CarrierWave::MiniMagick
    include CarrierWave::MimeTypes

    storage :file
    process :set_content_type

    def store_dir
      "uploads/place/#{model.place_id}/photos"
    end

    version :thumbnail do
      process :resize_to_fill => [250,156]
    end

    def get_exif(name)
      manipulate! do |img|
        return img["EXIF:" + name]
      end
    end

  end

end
