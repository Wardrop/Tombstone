require_relative '../spec_helper'

module Tombstone
  describe Role do
    
    it "is configured correctly" do
      role = Role.with_pk(1)
      role.type.should == 'reservee'
    end
    
    it "has an associated person" do
      role = Role.with_pk(1)
      role.person.should be_a(Person)
    end
    
    it "has an associated mailing and residential contact" do
      role = Role.with_pk(1)
      role.residential_contact.should be_a(Contact)
      role.mailing_contact.should be_a(Contact)
      role.residential_contact.should_not == role.mailing_contact
    end
    
    it "has many associated allocations" do
      role = Role.with_pk(1)
      role.allocations.should be_a(Array)
      role.allocations[0].should be_a(Allocation)
    end
    
    context "create role from a hash" do
      before :all do
        @person = Person.new(
          'title' => 'Mr',
          'surname' => 'Royson',
          'given_name' => 'Jose',
          'gender' => 'male',
          'date_of_birth' => '1987-10-01 00:00:00 UTC'
        ).save
        @contact = Contact.new(
          'street_address' => '26 Horse St',
          'town' => 'Mareeba',
          'state' => 'QLD',
          'country' => 'Australia',
          'postal_code' => '4880',
          'email' => 'royco@gmail.com',
          'primary_phone' => '(07) 5511 5511'
        ).save
      end
      
      it "can create a role with all new objects" do
        errors = Sequel::Model::Errors.new
        role_hash = {
            'type' => 'reservee',
            'person' => {
            'title' => 'Mr',
            'surname' => 'Royson',
            'given_name' => 'Jose',
            'gender' => 'male',
            'date_of_birth' => '1987-10-01 00:00:00 UTC'
          },
          'residential_contact' => {
            'street_address' => '26 Horse St',
            'town' => 'Mareeba',
            'state' => 'QLD',
            'country' => 'Australia',
            'postal_code' => '4880',
            'email' => 'royco@gmail.com',
            'primary_phone' => '(07) 5511 5511'
          },
          'mailing_contact' => {
            'street_address' => '18 Shetlin St',
            'town' => 'Mareeba',
            'state' => 'QLD',
            'country' => 'Australia',
            'postal_code' => '4880',
            'email' => 'royco@gmail.com',
            'primary_phone' => '(07) 4028 2222'
          }
        }
        role = Role.create_from(role_hash, errors)
        role.should_not be_nil
        role.person.should be_a(Person)
        role.residential_contact.should be_a(Contact)
        role.mailing_contact.should be_a(Contact)
      end
      
      it "can create a role using existing bjects" do
        errors = Sequel::Model::Errors.new
        role_hash = {
          'type' => 'reservee',
          'person' => {
            'id' => @person.id
          },
          'residential_contact' => {
            'id' => @contact.id
          },
          'mailing_contact' => {
            'id' => @contact.id
          }
        }
        role = Role.create_from(role_hash, errors)
        role.should_not be_nil
        role.person.id.should == @person.id
        role.residential_contact.id.should == @contact.id
        role.mailing_contact.id.should == @contact.id
      end
      
      it "can update existing objects when creating role" do
        errors = Sequel::Model::Errors.new
        role_hash = {
          'type' => 'reservee',
          'person' => {
            'id' => @person.id,
            'surname' => 'facer'
          },
          'residential_contact' => {
            'id' => @contact.id,
            'postal_code' => '5555'
          },
          'mailing_contact' => {
            'id' => @contact.id,
            'postal_code' => '6666'
          }
        }
        role = Role.create_from(role_hash, errors)
        role.should_not be_nil
        role.person.surname.should == 'facer'
        role.residential_contact.postal_code.should == '5555'
        role.mailing_contact.postal_code.should == '6666'
      end
      
      it "updates the given error object with any validation errors" do
        errors = Sequel::Model::Errors.new
        role_hash = {
          'type' => 'reservee',
          'person' => {
            'surname' => 'f'
          },
          'residential_contact' => {
            'id' => @contact.id
          }
        }
        role = Role.create_from(role_hash, errors)
        errors.should_not be_empty
        errors = Sequel::Model::Errors.new
        role_hash = {
          'type' => 'reservee',
          'person' => {
            'id' => @person.id
          },
          'residential_contact' => {
            'id' => @contact.id,
            'postal_code' => 'a'
          }
        }
        role = Role.create_from(role_hash, errors)
        errors.should_not be_empty
      end
    end
    
  end
end