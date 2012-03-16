db = Sequel::Model.db
db.loggers << Logger.new(STDOUT)

namespace :db do
  
  desc "Create/recreate database schema"
  task :create do
    Sequel.extension :migration 

    # Recreate the database tables
    db.drop_table(*db.tables)
    Sequel::Migrator.apply(db, File.expand_path('../../db/migrations', __FILE__))
  end
  
  desc "Populates the database with dummy data"
  task :populate do
    db.execute("EXEC sp_MSForEachTable 'TRUNCATE TABLE ?'")
    
    db[:person] << {title: 'Mr', surname: 'Fickle', given_name: 'Roger', middle_initials: 'D', gender: 'Male', date_of_birth: Date.parse('09/03/1934'), date_of_death: nil}
    db[:person] << {title: 'Mr', surname: 'Bunson', given_name: 'Sam', middle_initials: 'F', gender: 'Male', date_of_birth: Date.parse('27/11/1971'), date_of_death: nil}
    db[:person] << {title: 'Mr', surname: 'Rojenstien', given_name: 'Phillip', middle_initials: 'R', gender: 'Male', date_of_birth: Date.parse('26/01/1988'), date_of_death: nil}
    
    db[:contact] << {email: 'manager@bigbiz.com', street_address: '56 Hughey Cl', town: 'Mareeba', state: 'Queensland', postal_code: 4880, primary_phone: '(07) 4092 6735', secondary_phone: '0422 454 829'}
    db[:contact] << {email: 'littlesamurai@myfantasy.com', street_address: '65 Rankin St', town: 'Mareeba', state: 'Queensland', postal_code: 4880, primary_phone: '(07) 4095 4116', secondary_phone: nil}
    db[:contact] << {email: 'emochick56@hotmail.com', street_address: '72 Ray Rd', town: 'Mareeba', state: 'Queensland', postal_code: 4880, primary_phone: '(07) 5555 5555', secondary_phone: nil}
    db[:contact] << {email: 'me@iamme.com', street_address: '4 Gordon St', town: 'Malanda', state: 'Queensland', postal_code: 4873, primary_phone: '(07) 6666 6666', secondary_phone: nil}
    db[:contact] << {email: 'bickboy@gmail.com', street_address: '11-14 Jaquillan St', town: 'Atherton', state: 'Queensland', postal_code: 4873, primary_phone: '(07) 7777 7777', secondary_phone: nil}
    db[:contact] << {email: 'enquiries@guilfoyles.com.au', street_address: '32 Constance St', town: 'Mareeba', state: 'Queensland', postal_code: 4880, primary_phone: '(07) 8787 8787', secondary_phone: nil}
    db[:contact] << {email: 'enquiries@guilfoyles.com.au', street_address: '29 Mabel St', town: 'Atherton', state: 'Queensland', postal_code: 4872, primary_phone: '(07) 9239 2392', secondary_phone: nil}
  
    db[:role] << {person_id: 1, type: 'reservee', residential_contact_id: 1, mailing_contact_id: 2}
    db[:role] << {person_id: 2, type: 'next_of_kin', residential_contact_id: 5, mailing_contact_id: 4}
    db[:role] << {person_id: 3, type: 'applicant', residential_contact_id: 3}
    db[:role] << {person_id: 1, type: 'deceased', residential_contact_id: 2}
    db[:role] << {person_id: 3, type: 'reservee', residential_contact_id: 3, mailing_contact_id: 3}
    
    # db[:allocation] << {role1_id: 1, role2_id: 2, type: 'Next of Kin'}
    # db[:allocation] << {role1_id: 3, role2_id: 2, type: 'Colleague'}
    # db[:allocation] << {role1_id: 1, role2_id: 3, type: 'Colleague'}
    
    db[:allocation].insert(type: 'reservation', place_id: 7,  status: 'approved')
    id = db[:allocation].insert(type: 'reservation', place_id: 8,  status: 'approved', location_description: 'Next to the big rock.', comments: 'Just some dummy comment text.')
    db.run('SET IDENTITY_INSERT [allocation] ON')
    db[:allocation].insert(id: id, type: 'interment', place_id: 8,  status: 'approved', funeral_director_id: 1, interment_date: (DateTime.now + 7), interment_type: 'coffin', comments: 'Call office prior burial.')
    db.run('SET IDENTITY_INSERT [allocation] OFF')
    db[:allocation].insert(type: 'interment', place_id: 13, status: 'approved', funeral_director_id: 1, interment_date: (DateTime.now + 3), interment_type: 'ashes', burial_requirements: 'On back please')
    db[:allocation].insert(type: 'interment', place_id: 15, status: 'deleted', funeral_director_id: 1, interment_date: (DateTime.now + 10), interment_type: 'ashes', burial_requirements: 'To be provided')
    
    db[:role_association] << {role_id: 1, allocation_id: 2, allocation_type: 'reservation'}
    db[:role_association] << {role_id: 3, allocation_id: 2, allocation_type: 'reservation'}
    db[:role_association] << {role_id: 2, allocation_id: 2, allocation_type: 'interment'}
    db[:role_association] << {role_id: 4, allocation_id: 3, allocation_type: 'interment'}
    db[:role_association] << {role_id: 5, allocation_id: 1, allocation_type: 'reservation'}
    
    db[:transaction] << {:allocation_id => 2, :allocation_type => 'interment', :receipt_no => 69242}
    db[:transaction] << {:allocation_id => 2, :allocation_type => 'reservation', :receipt_no => 72353}
    
    db[:funeral_director] << {:name => "Guilfoyles Mareeba", :residential_contact_id => 6, :mailing_contact_id => 6}
    db[:funeral_director] << {:name => "Guilfoyles Atherton", :residential_contact_id => 7}
    
    db[:user] << {id: 'tomw', name: 'Tom Wardrop', role: 'supervisor'}
    db[:user] << {id: 'tatej', name: 'Tate Jones', role: 'operator'}
    db[:user] << {id: 'rogerj', name: 'Roger Johnson', role: 'operator'}
    
        
    db[:place] << {name: 'Atherton Cemetery', type: 'cemetery', status: 'available'}
    db[:place] << {name: 'Mareeba Cemetery', type: 'cemetery', status: 'available'}
    db[:place] << {parent_id: 2, name: 'Plaque on Beam', type: 'section', status: 'available'}
    db[:place] << {parent_id: 2, name: 'Lawn', type: 'section', status: 'available', max_interments: 2}
    db[:place] << {parent_id: 4, name: 'Row A', type: 'row', status: 'available'}
    db[:place] << {parent_id: 4, name: 'Row B', type: 'row', status: 'available'}
    db[:place] << {parent_id: 5, name: 'Plot 16', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 5, name: 'Plot 17', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 5, name: 'Plot 18', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 3, name: 'Row A', type: 'row', status: 'available'}
    db[:place] << {parent_id: 3, name: 'Row B', type: 'row', status: 'available', max_interments: 3}
    db[:place] << {parent_id: 3, name: 'Row C', type: 'row', status: 'available'}
    db[:place] << {parent_id: 10, name: 'Plot 3', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 10, name: 'Plot 4', type: 'plot', status: 'unavailable'}
    db[:place] << {parent_id: 10, name: 'Plot 5', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 10, name: 'Plot 6', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 10, name: 'Plot 7', type: 'plot', status: 'unavailable'}
    db[:place] << {parent_id: 10, name: 'Plot 8', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 10, name: 'Plot 9', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 10, name: 'Plot 10', type: 'plot', status: 'unavailable'}
    db[:place] << {parent_id: 10, name: 'Plot 11', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 11, name: 'Plot 37', type: 'plot', status: 'unavailable'}
    db[:place] << {parent_id: 11, name: 'Plot 38', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 11, name: 'Plot 39', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 11, name: 'Plot 40', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 11, name: 'Plot 41', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 11, name: 'Plot 42', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 11, name: 'Plot 43', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 11, name: 'Plot 44', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 11, name: 'Plot 45', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 11, name: 'Plot 46', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 11, name: 'Plot 47', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 11, name: 'Plot 48', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 11, name: 'Plot 49', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 11, name: 'Plot 50', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 11, name: 'Plot 51', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 11, name: 'Plot 52', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 11, name: 'Plot 53', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 11, name: 'Plot 54', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 11, name: 'Plot 55', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 12, name: 'Plot 21', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 12, name: 'Plot 22', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 12, name: 'Plot 23', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 12, name: 'Plot 24', type: 'plot', status: 'available'}
    db[:place] << {parent_id: 12, name: 'Plot 25', type: 'plot', status: 'available'}
    
    garden_id = db[:place].insert(parent_id: 2, name: 'Garden', type: 'section', status: 'available')
    db[:place] << {parent_id: garden_id, name: 'By The Roses', type: 'sub-section', status: 'available'}
    db[:place] << {parent_id: garden_id + 1, name: 'Row A', type: 'row', status: 'available'}
    db[:place] << {parent_id: garden_id + 1, name: 'Row B', type: 'row', status: 'available'}
    db[:place] << {parent_id: garden_id + 2, name: 'Plot 22', type: 'plot', status: 'available'}
    db[:place] << {parent_id: garden_id + 2, name: 'Plot 23', type: 'plot', status: 'available'}
    db[:place] << {parent_id: garden_id + 2, name: 'Plot 24', type: 'plot', status: 'available'}
    db[:place] << {parent_id: garden_id + 3, name: 'Plot 6', type: 'plot', status: 'available'}
    db[:place] << {parent_id: garden_id + 3, name: 'Plot 7', type: 'plot', status: 'available'}
  end
  
end