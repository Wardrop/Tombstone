Sequel.migration do
  change do
    alter_table :blob do
      drop_column :timestamp
      drop_column :enabled
      add_column :exif, :varbinary, :size => :max
      add_column :created_by, String, :size => 32
      add_column :created_at, DateTime
      add_column :modified_by, String, :size => 32
      add_column :modified_at, DateTime
    end
  end
end