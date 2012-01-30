Sequel.migration do
  DB.create_table :party do
    primary_key :id
    String :title, :size => 16
    String :surname, :size => 40
    String :given_name, :size => 40
    String :initials, :size => 3
    String :gender, :size => 6
    DateTime :date_of_birth
    DateTime :date_of_death
    String :modified_by, :size => 32
    DateTime :last_modified
  end
  
  DB.create_table :role do
    primary_key :id
    Integer :party_id
    String :type, :size => 32
    Integer :residential_address_id
    Integer :mailing_address_id
    String :modified_by, :size => 32
    DateTime :last_modified
  end
  
  DB.create_table :relationship do
    primary_key :id
    Integer :role1_id
    Integer :role2_id
    String :type, :size => 32
    String :modified_by, :size => 32
    DateTime :last_modified
  end
  
  DB.create_table :address do
    primary_key :id
    String :street_address
    String :town, :size => 64
    String :state, :size => 32
    smallint :postal_code
    String :primary_phone, :size => 16
    String :secondary_phone, :size => 16
    String :modified_by, :size => 32
    DateTime :last_modified
  end
  
  DB.create_table :reservation do
    primary_key :id
    Integer :place_id
    Integer :reservee_id
    String :status, :size => 32
    String :interment_type, :size => 32
    ntext :comments
    String :adjacent_interment, :size => 255
    String :modified_by, :size => 32
    DateTime :last_modified
  end
  
  DB.create_table :place do
    primary_key :id
    Integer :parent_id
    String :name, :size => 64
    String :code_name, :size => 12
    String :type, :size => 32
    String :state, :size => 32
    tinyint :max_interments
    String :modified_by, :size => 32
    DateTime :last_modified
  end
  
  DB.create_table :user do
    String :id, :size => 64, :primary_key => true
    String :name, :size => 64
    String :role, :size => 32
  end
end