Sequel.migration do
  up do 
    create_table :person do
      primary_key :id
      String :title, :size => 16
      String :surname, :size => 40
      String :given_name, :size => 40
      String :middle_initials, :size => 3
      String :gender, :size => 6
      DateTime :date_of_birth
      DateTime :date_of_death
      String :modified_by, :size => 32
      DateTime :modified_at
      String :created_by, :size => 32
      DateTime :created_at
    end
  
    create_table :role do
      primary_key :id
      Integer :person_id
      String :type, :size => 32
      Integer :residential_contact_id
      Integer :mailing_contact_id
      String :modified_by, :size => 32
      DateTime :modified_at
      String :created_by, :size => 32
      DateTime :created_at
    end
    
    create_table :role_association do
      Integer :role_id
      Integer :allocation_id
      String :allocation_type, :size => 32
      primary_key [:role_id, :allocation_id]
    end
    
    create_table :contact do
      primary_key :id
      String   :email, :size => 255
      String   :street_address
      String   :town, :size => 64
      String   :state, :size => 32
      smallint :postal_code
      String   :primary_phone, :size => 16
      String   :secondary_phone, :size => 16
      String   :modified_by, :size => 32
      DateTime :modified_at
      String   :created_by, :size => 32
      DateTime :created_at
    end
    
    create_table :allocation do
      primary_key [:id, :type]
      Integer  :id, :auto_increment => true, :null => false
      String   :type, :size => 32
      Integer  :place_id
      String   :status, :size => 32
      String   :interment_type, :size => 32
      Integer  :funeral_director_id
      String   :funeral_director_name, :size => 128
      String   :funeral_service_location, :size => 128
      DateTime :advice_received_date
      DateTime :interment_date
      String   :location_description, :size => 255
      ntext    :burial_requirements
      ntext    :comments
      String   :modified_by, :size => 32
      DateTime :modified_at
      String   :created_by, :size => 32
      DateTime :created_at
    end
    
    create_table :place do
      primary_key :id
      Integer :parent_id
      String :name, :size => 64
      String :code_name, :size => 12
      String :type, :size => 32
      String :status, :size => 32
      tinyint :max_interments
      String :modified_by, :size => 32
      DateTime :modified_at
      String :created_by, :size => 32
      DateTime :created_at
    end
    
    create_table :transaction do
      primary_key [:allocation_id, :allocation_type, :receipt_no]
      Integer :allocation_id
      String :allocation_type, :size => 32
      String :receipt_no, :size => 32
    end
    
    create_table :funeral_director do
      primary_key :id
      String :name, :size => 64
      Integer :residential_contact_id
      Integer :mailing_contact_id
    end
    
    create_table :user do
      String :id, :size => 64, :primary_key => true
      String :role, :size => 32
    end

    create_table :blob do
      primary_key [:id, :place_id]
      Integer :id, :auto_increment => true, :null => false
      Integer :place_id, :null => false
      String :name, :size => 255
      String :content_type, :size => 100
      Integer :size, :size => 100
      String :file, :size => 255
      String :enabled, :size => 5
      DateTime :timestamp
      String :created_by, :size => 32
      DateTime :created_at
    end

  end
end