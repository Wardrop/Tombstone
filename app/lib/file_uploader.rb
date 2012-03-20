module Tombstone

  include CarrierWave

  class FileUploader < CarrierWave::Uploader::Base
    storage :file
  end
end
