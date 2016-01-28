Sequel.migration do
  up do
    self << "DELETE FROM blob"
    alter_table :blob do
      drop_column :file
      add_column :data, :varbinary, :size => :max
      add_column :thumbnail, :varbinary, :size => :max
    end
  end
end