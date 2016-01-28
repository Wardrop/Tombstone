Sequel.migration do
  up do
    self << "ALTER TABLE contact ALTER COLUMN postal_code nvarchar(12)"
  end
  
  down do
    self << "ALTER TABLE contact ALTER COLUMN postal_code smallint"
  end
end
