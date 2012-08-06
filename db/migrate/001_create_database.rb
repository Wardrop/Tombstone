Sequel.migration do
  up do 
    create_table :person do
      primary_key :id
      nvarchar :title, :size => 16
      nvarchar :surname, :size => 40
      nvarchar :given_name, :size => 40
      nvarchar :middle_initials, :size => 3
      nvarchar :gender, :size => 20
      DateTime :date_of_birth
      DateTime :date_of_death
      nvarchar :modified_by, :size => 32
      DateTime :modified_at
      nvarchar :created_by, :size => 32
      DateTime :created_at
    end
  
    create_table :role do
      primary_key :id
      Integer :person_id
      nvarchar :type, :size => 32
      Integer :residential_contact_id
      Integer :mailing_contact_id
      nvarchar :modified_by, :size => 32
      DateTime :modified_at
      nvarchar :created_by, :size => 32
      DateTime :created_at
    end
    
    create_table :role_association do
      Integer :role_id
      Integer :allocation_id
      nvarchar :allocation_type, :size => 32
      primary_key [:role_id, :allocation_id]
    end
    
    create_table :contact do
      primary_key :id
      nvarchar   :email, :size => 255
      nvarchar   :street_address, :size => 255
      nvarchar   :town, :size => 64
      nvarchar   :state, :size => 32
      smallint :postal_code
      nvarchar   :primary_phone, :size => 16
      nvarchar   :secondary_phone, :size => 16
      nvarchar   :modified_by, :size => 32
      DateTime :modified_at
      nvarchar   :created_by, :size => 32
      DateTime :created_at
    end
    
    create_table :allocation do
      primary_key [:id, :type]
      Integer  :id, :auto_increment => true, :null => false
      nvarchar   :type, :size => 32
      Integer  :place_id
      nvarchar   :status, :size => 32
      nvarchar   :interment_type, :size => 32
      Integer  :funeral_director_id
      nvarchar   :funeral_director_name, :size => 128
      nvarchar   :funeral_service_location, :size => 128
      DateTime :advice_received_date
      DateTime :interment_date
      nvarchar   :location_description, :size => 255
      ntext    :burial_requirements
      ntext    :comments
      nvarchar   :modified_by, :size => 32
      DateTime :modified_at
      nvarchar   :created_by, :size => 32
      DateTime :created_at
    end
    
    create_table :place do
      primary_key :id
      Integer :parent_id
      nvarchar :name, :size => 64
      nvarchar :code_name, :size => 12
      nvarchar :type, :size => 32
      nvarchar :status, :size => 32
      tinyint :max_interments
      nvarchar :modified_by, :size => 32
      DateTime :modified_at
      nvarchar :created_by, :size => 32
      DateTime :created_at
    end
    
    create_table :transaction do
      primary_key [:allocation_id, :allocation_type, :receipt_no]
      Integer :allocation_id
      nvarchar :allocation_type, :size => 32
      nvarchar :receipt_no, :size => 32
    end
    
    create_table :funeral_director do
      primary_key :id
      nvarchar :name, :size => 64
      Integer :residential_contact_id
      Integer :mailing_contact_id
    end
    
    create_table :user do
      nvarchar :id, :size => 64, :primary_key => true
      nvarchar :role, :size => 32
    end

    create_table :blob do
      primary_key :id
      Integer :id, :auto_increment => true, :null => false
      Integer :place_id, :null => false
      nvarchar :name, :size => 255
      nvarchar :content_type, :size => 100
      Integer :size
      nvarchar :file, :size => 255
      bit :enabled
      DateTime :timestamp
      nvarchar :created_by, :size => 32
      DateTime :created_at
    end

  end
end