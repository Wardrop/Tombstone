require 'date'
require 'sequel'

Sequel.extension :migration 
DB = Sequel.connect({:adapter => 'tinytds'}.merge(SPEC_CONFIG[:db]))

base_dir = "#{File.dirname(__FILE__)}/.."
Dir.glob("#{base_dir}/models/*.rb") { |file| require file }

# Recreate the database tables
DB.drop_table(*DB.tables)
Sequel::Migrator.apply(DB,'../db')

# Setup Permissions object
Tombstone::Permissions.map = SPEC_CONFIG[:roles]

# Pre-populate the database with test data
DB[:party] << {title: 'Mr', surname: 'Wardrop', given_name: 'Tom', initials: 'D', gender: 'Male', date_of_birth: Date.parse('19/06/1990'), date_of_death: nil}
DB[:party] << {title: 'Mr', surname: 'Jones', given_name: 'Tate', initials: 'F', gender: 'Male', date_of_birth: Date.parse('27/03/1971'), date_of_death: nil}
DB[:party] << {title: 'Mr', surname: 'Stroud', given_name: 'Hilton', initials: 'R', gender: 'Male', date_of_birth: Date.parse('26/01/1982'), date_of_death: nil}

DB[:address] << {address: '6 Isabel St', town: 'Mareeba', state: 'Queensland', postal_code: 4880, primary_phone: '(07) 4092 1223', secondary_phone: '0413 393 129'}
DB[:address] << {address: '65 Rankin St', town: 'Mareeba', state: 'Queensland', postal_code: 4880, primary_phone: '(07) 4043 4436', secondary_phone: nil}
DB[:address] << {address: '72 Ray Rd', town: 'Mareeba', state: 'Queensland', postal_code: 4880, primary_phone: '(07) 5555 5555', secondary_phone: nil}
DB[:address] << {address: '4 Gordon St', town: 'Malanda', state: 'Queensland', postal_code: 4873, primary_phone: '(07) 6666 6666', secondary_phone: nil}

DB[:role] << {party_id: 1, type: 'reservee', residential_address_id: 1, mailing_address_id: 2}
DB[:role] << {party_id: 2, type: 'contact', residential_address_id: 4, mailing_address_id: nil}
DB[:role] << {party_id: 3, type: 'contact', residential_address_id: 3, mailing_address_id: nil}

DB[:relationship] << {role1_id: 1, role2_id: 2, type: 'Next of Kin'}
DB[:relationship] << {role1_id: 3, role2_id: 2, type: 'Colleague'}
DB[:relationship] << {role1_id: 1, role2_id: 3, type: 'Colleague'}

DB[:user] << {id: 'tomw', name: 'Tom Wardrop', role: 'supervisor'}
DB[:user] << {id: 'tatej', name: 'Tate Jones', role: 'operator'}
DB[:user] << {id: 'rogers', name: 'Roger Johnson', role: 'operator'}