Sequel.migration do
  up do
    create_table :legacy do
      primary_key [:allocation_id, :key]
      Integer :allocation_id
      String :key, :size => 64
      String :value, :size => 255, :null => true
    end
  end
  
  down do
    drop_table :legacy
  end
end