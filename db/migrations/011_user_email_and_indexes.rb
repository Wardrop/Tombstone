Sequel.migration do
  change do
    # Add indexes on all foreign keys
    alter_table :allocation do
      add_index :place_id
      add_index :funeral_director_id
    end
    
    alter_table :blob do
      add_primary_key [:id]
      add_index :place_id
    end
    
    alter_table :funeral_director do
      add_index :residential_contact_id
      add_index :mailing_contact_id
    end
    
    alter_table :place do
      add_index :parent_id
    end
    
    alter_table :role do
      add_index :person_id
      add_index :residential_contact_id
      add_index :mailing_contact_id
    end
    
    alter_table :role_association do
      add_index :allocation_id
    end
    
  end
end