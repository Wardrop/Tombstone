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
      process :resize_to_fill => [320,200]
    end

  end

end
