CONFIG = eval(File.read('./config.rb'))

namespace :db do
  require 'sequel'
  
  desc "Recreate database schema"
  task :recreate do
    Sequel.extension :migration 
    DB = Sequel.connect({:adapter => 'tinytds'}.merge(CONFIG[:development][:db]))
    
    # Recreate the database tables
    DB.drop_table(*DB.tables)
    Sequel::Migrator.apply(DB, File.join(File.dirname(__FILE__), '/db'))
  end
  
  desc "Populates the database with dummy data"
  task :populate do
    db = Sequel.connect({:adapter => 'tinytds'}.merge(CONFIG[:development][:db]))
    db.execute("EXEC sp_MSForEachTable 'TRUNCATE TABLE ?'")
    
    db[:party] << {title: 'Mr', surname: 'Fickle', given_name: 'Roger', initials: 'D', gender: 'Male', date_of_birth: Date.parse('09/03/1934'), date_of_death: nil}
    db[:party] << {title: 'Mr', surname: 'Bunson', given_name: 'Sam', initials: 'F', gender: 'Male', date_of_birth: Date.parse('27/11/1971'), date_of_death: nil}
    db[:party] << {title: 'Mr', surname: 'Rojenstien', given_name: 'Phillip', initials: 'R', gender: 'Male', date_of_birth: Date.parse('26/01/1988'), date_of_death: nil}
    
    db[:address] << {street_address: '56 Hughey Cl', town: 'Mareeba', state: 'Queensland', postal_code: 4880, primary_phone: '(07) 4092 6735', secondary_phone: '0422 454 829'}
    db[:address] << {street_address: '65 Rankin St', town: 'Mareeba', state: 'Queensland', postal_code: 4880, primary_phone: '(07) 4095 4116', secondary_phone: nil}
    db[:address] << {street_address: '72 Ray Rd', town: 'Mareeba', state: 'Queensland', postal_code: 4880, primary_phone: '(07) 5555 5555', secondary_phone: nil}
    db[:address] << {street_address: '4 Gordon St', town: 'Malanda', state: 'Queensland', postal_code: 4873, primary_phone: '(07) 6666 6666', secondary_phone: nil}
    db[:address] << {street_address: '11-14 Jaquillan St', town: 'Atherton', state: 'Queensland', postal_code: 4873, primary_phone: '(07) 7777 7777', secondary_phone: nil}
    
    db[:role] << {party_id: 1, type: 'reservee', residential_address_id: 1, mailing_address_id: 2}
    db[:role] << {party_id: 2, type: 'contact', residential_address_id: 5, mailing_address_id: 4}
    db[:role] << {party_id: 3, type: 'contact', residential_address_id: 3}
    db[:role] << {party_id: 1, type: 'contact', residential_address_id: 2}
    
    db[:relationship] << {role1_id: 1, role2_id: 2, type: 'Next of Kin'}
    db[:relationship] << {role1_id: 3, role2_id: 2, type: 'Colleague'}
    db[:relationship] << {role1_id: 1, role2_id: 3, type: 'Colleague'}
    
    db[:place] << {name: 'Atherton Cemetery', type: 'cemetery', state: 'available'}
    db[:place] << {name: 'Mareeba Cemetery', type: 'cemetery', state: 'available'}
    db[:place] << {parent_id: 2, name: 'Plaque on Beam', type: 'section', state: 'available'}
    db[:place] << {parent_id: 2, name: 'Lawn', type: 'section', state: 'available'}
    db[:place] << {parent_id: 4, name: 'Row A', type: 'row', state: 'available'}
    db[:place] << {parent_id: 4, name: 'Row B', type: 'row', state: 'available'}
    db[:place] << {parent_id: 5, name: 'Plot 16', type: 'plot', state: 'available'}
    
    db[:reservation] << {place_id: 7, reservee_id: 1, status: 'approved'}
    
    db[:user] << {id: 'tomw', name: 'Tom Wardrop', role: 'supervisor'}
    db[:user] << {id: 'tatej', name: 'Tate Jones', role: 'operator'}
    db[:user] << {id: 'rogers', name: 'Roger Johnson', role: 'operator'}
  end
  
end

desc "Drop into an application-like IRB prompt"
task :irb do
  require './app'
  require 'irb'
  ARGV.clear
  IRB.start
end