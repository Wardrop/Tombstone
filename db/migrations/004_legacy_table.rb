Sequel.migration do
  up do
    create_table :legacy do
      primary_key [:allocation_id, :key]
      Integer :allocation_id
      nvarchar :key, :size => 64
      nvarchar :value, :size => 255, :null => true
    end
  end
  
  down do
    drop_table :legacy
  end
end