Sequel.migration do
  change do
    alter_table :blob do
      drop_column :timestamp
      drop_column :enabled
      add_column :exif, :varchar, :size => :max
      add_column :modified_by, :nvarchar, :size => 32
      add_column :modified_at, DateTime
    end
  end
end