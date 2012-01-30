require 'date'
require 'sequel'

current_dir = File.dirname(__FILE__)

Sequel.extension :migration 
DB = Sequel.connect({:adapter => 'tinytds'}.merge(SPEC_CONFIG[:db]))

Dir.glob(File.join(current_dir, "/../../models/*.rb")) { |file| require file }

# Recreate the database tables
DB.drop_table(*DB.tables)
Sequel::Migrator.apply(DB, File.join(current_dir, '/../../db'))

# Setup Permissions object
Tombstone::Permissions.map = SPEC_CONFIG[:roles]

# Pre-populate the database with test data
DB[:party] << {title: 'Mr', surname: 'Fickle', given_name: 'Roger', initials: 'D', gender: 'Male', date_of_birth: Date.parse('09/03/1934'), date_of_death: nil}
DB[:party] << {title: 'Mr', surname: 'Bunson', given_name: 'Sam', initials: 'F', gender: 'Male', date_of_birth: Date.parse('27/11/1971'), date_of_death: nil}
DB[:party] << {title: 'Mr', surname: 'Rojenstien', given_name: 'Phillip', initials: 'R', gender: 'Male', date_of_birth: Date.parse('26/01/1988'), date_of_death: nil}

DB[:address] << {street_address: '56 Hughey Cl', town: 'Mareeba', state: 'Queensland', postal_code: 4880, primary_phone: '(07) 4092 6735', secondary_phone: '0422 454 829'}
DB[:address] << {street_address: '65 Rankin St', town: 'Mareeba', state: 'Queensland', postal_code: 4880, primary_phone: '(07) 4095 4116', secondary_phone: nil}
DB[:address] << {street_address: '72 Ray Rd', town: 'Mareeba', state: 'Queensland', postal_code: 4880, primary_phone: '(07) 5555 5555', secondary_phone: nil}
DB[:address] << {street_address: '4 Gordon St', town: 'Malanda', state: 'Queensland', postal_code: 4873, primary_phone: '(07) 6666 6666', secondary_phone: nil}
DB[:address] << {street_address: '11-14 Jaquillan St', town: 'Atherton', state: 'Queensland', postal_code: 4873, primary_phone: '(07) 7777 7777', secondary_phone: nil}
    
DB[:role] << {party_id: 1, type: 'reservee', residential_address_id: 3, mailing_address_id: 4}
DB[:role] << {party_id: 2, type: 'contact', residential_address_id: 5, mailing_address_id: 2}
DB[:role] << {party_id: 3, type: 'contact', residential_address_id: 1}
DB[:role] << {party_id: 1, type: 'contact', residential_address_id: 2}

DB[:relationship] << {role1_id: 1, role2_id: 2, type: 'Next of Kin'}
DB[:relationship] << {role1_id: 3, role2_id: 2, type: 'Colleague'}
DB[:relationship] << {role1_id: 1, role2_id: 3, type: 'Colleague'}

DB[:place] << {name: 'Atherton Cemetery', type: 'cemetery', state: 'available'}
DB[:place] << {name: 'Mareeba Cemetery', type: 'cemetery', state: 'available'}
DB[:place] << {parent_id: 2, name: 'Plaque on Beam', type: 'section', state: 'available'}
DB[:place] << {parent_id: 2, name: 'Lawn', type: 'section', state: 'available'}
DB[:place] << {parent_id: 4, name: 'Row A', type: 'row', state: 'available'}
DB[:place] << {parent_id: 4, name: 'Row B', type: 'row', state: 'available'}
DB[:place] << {parent_id: 5, name: 'Plot 16', type: 'plot', state: 'available'}

DB[:reservation] << {place_id: 7, reservee_id: 1, status: 'approved'}

DB[:user] << {id: 'tomw', name: 'Tom Wardrop', role: 'supervisor'}
DB[:user] << {id: 'tatej', name: 'Tate Jones', role: 'operator'}
DB[:user] << {id: 'rogers', name: 'Roger Johnson', role: 'operator'}