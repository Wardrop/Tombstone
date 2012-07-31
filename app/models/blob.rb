module Tombstone
  
  class Blob < BaseModel
    set_primary_key :id
    many_to_one :place, :key => [:place_id], :class => :'Tombstone::Place'
    
    # mount_uploader :file, PhotoUploader
  end
  
  class Photo < Blob
    set_dataset dataset.filter(:content_type.like 'image/%').order(:id.asc)
    set_primary_key :id
    
    def before_save
      super
      self.set(
        name: file.file.filename,
        content_type: file.file.content_type,
        size: file.file.size,
        timestamp: (DateTime.strptime(file.get_exif("DateTimeOriginal"), '%Y:%m:%d %H:%M:%S') rescue nil)
      )
    end
    
    def thumbnail
      file.thumbnail.url
    end
    
    def thumbnail_dimensions
      {
        width: Tombstone::PhotoUploader.dimensions[:thumbnail][0],
        height: Tombstone::PhotoUploader.dimensions[:thumbnail][1]
      }
    end

    def extract_geolocation
      return unless img
      img_lat = img.get_exif_by_entry('GPSLatitude')[0][1].split(', ') rescue nil
      img_lng = img.get_exif_by_entry('GPSLongitude')[0][1].split(', ') rescue nil

      lat_ref = img.get_exif_by_entry('GPSLatitudeRef')[0][1] rescue nil
      lng_ref = img.get_exif_by_entry('GPSLongitudeRef')[0][1] rescue nil

      return unless img_lat && img_lng && lat_ref && lng_ref

      latitude = to_frac(img_lat[0]) + (to_frac(img_lat[1])/60) + (to_frac(img_lat[2])/3600)
      longitude = to_frac(img_lng[0]) + (to_frac(img_lng[1])/60) + (to_frac(img_lng[2])/3600)

      latitude = latitude * -1 if lat_ref == 'S' # (N is +, S is -)
      longitude = longitude * -1 if lng_ref == 'W' # (W is -, E is +)

      puts latitude
      puts longitude
    end

    def to_frac(strng)
      numerator, denominator = strng.split('/').map(&:to_f)
      denominator ||= 1
      numerator/denominator
    end
  end
  
end




