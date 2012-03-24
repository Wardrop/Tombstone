module Tombstone
  class Blob < BaseModel
    set_primary_key [:id, :place_id]
    unrestrict_primary_key
    many_to_one :place, :key => [:place_id], :class => :'Tombstone::Place'

    mount_uploader :file, PhotoUploader

    def validate
      super
      validates_presence :name
      validates_max_length 255, :name
    end

    def write_data_identifier
      self[:content_type] = file.file.content_type
      self[:name] = self.file.filename
      self[:size] = self.file.size
    end
  end
end