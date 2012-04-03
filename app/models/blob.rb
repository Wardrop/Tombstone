module Tombstone
  class Blob < BaseModel

    set_primary_key [:id, :place_id]
    unrestrict_primary_key
    many_to_one :place, :key => [:place_id], :class => :'Tombstone::Place'

    mount_uploader :file, PhotoUploader

    def write_file_identifier
      self[:content_type] = file.file.content_type
      self[:name] = self.file.filename
      self[:size] = self.file.size
      self[:file] = self.file.filename
      self[:enabled] = 'FALSE'
      self[:timestamp] = get_exif_date_time(self.file.get_exif("DateTimeOriginal"))

      ##extract_geolocation

      #2010:07:05 11:57:37
      #puts self.file.get_exif("GPSLatitude")
      #puts self.file.get_exif("GPSLongitude")
      #puts self.file.get_exif("GPSLatitudeRef")
      #puts self.file.get_exif("GPSLongitudeRef")
      ## GPSLatitude  GPSLongitude GPSLatitudeRef  GPSLongitudeRef
    end

    def get_exif_date_time(date_time)
      DateTime.strptime(date_time +  DateTime.now.strftime("%Z"), "%Y:%m:%d %H:%M:%S %Z")
    end

    def extract_geolocation

      ##img = Magick::Image.read(self.file)[0] rescue nil

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



