Sequel.migration do
  up do
    add_column :allocation, :alternate_reservee, String, :size => 255
    self << "ALTER TABLE [person] ALTER COLUMN surname nvarchar(64)"
  end
  
  down do
    drop_column :allocation, :alternate_reservee
    self << "ALTER TABLE [person] ALTER COLUMN surname nvarchar(40)"
  end
end