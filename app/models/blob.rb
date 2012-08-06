require 'stringio'

module Tombstone
  
  class Blob < BaseModel
    set_primary_key :id
    many_to_one :place, :key => [:place_id], :class => :'Tombstone::Place'
    delegate :thumbnail_dimensions, :to => self
    serialize_attributes :marshal, :exif
    lazy_attributes :data, :thumbnail
    
    class << self
      def thumbnail_dimensions
      {
        width: 256,
        height: 160
      }
      end
    end
    
    def before_save
      begin
        self.exif = EXIFR::JPEG.new(StringIO.new(data)).to_hash
      rescue EXIFR::MalformedImage
        begin
          self.exif = EXIFR::TIFF.new(StringIO.new(data)).to_hash
        rescue EXIFR::MalformedImage; end
      end

      if exif
        # Waiting for a limitation of the JSON library to be resolved before allowing all exif data which includes non-finite float values (NaN, Infinite, etc).
        exif = {:date_time => exif[:date_time]}

        #exif.delete :xmp # We put XMP in the too hard basket due to its character encoding difficulties.
        #exif.each_key do |k|
        #  if Float === exif[k] && exif[k].nan?
        #    exif[k] = nil
        #  elsif String === exif[k]
        #    exif[k].encode! Encoding::UTF_8, :undef => :replace
        #  end
        #end
      end
      super
    end
  end
  
end




