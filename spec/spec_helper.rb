ENV['RACK_ENV'] = 'spec'

require 'date'
require 'sequel'
require_relative '../app/app.rb'

LDAP_USER = {username: 'lanuser', password: 'M@1lb0t!'}

# Test data
db = Sequel::Model.db
db.execute("EXEC sp_MSForEachTable 'if (''?'' <> ''[dbo].[FUNERAL_DIRECTOR]'' AND ''?'' <> ''[dbo].[CONTACT]'' AND ''?'' <> ''[dbo].[SCHEMA_INFO]'') TRUNCATE TABLE ?'")

db[:person] << {title: 'Mr', surname: 'Fickle', given_name: 'Roger', middle_name: 'D', gender: 'male', date_of_birth: DateTime.parse('09/03/1934'), date_of_death: nil}
db[:person] << {title: 'Mr', surname: 'Bunson', given_name: 'Sam', middle_name: 'F', gender: 'male', date_of_birth: DateTime.parse('27/11/1971'), date_of_death: nil}
db[:person] << {title: 'Mr', surname: 'Rojenstien', given_name: 'Phillip', middle_name: 'R', gender: 'male', date_of_birth: DateTime.parse('26/01/1988'), date_of_death: nil}

db[:contact].where(email: ['manager@bigbiz.com','littlesamurai@myfantasy.com','emochick56@hotmail.com','me@iamme.com','bickboy@gmail.com']).delete
contact1 = db[:contact].insert(email: 'manager@bigbiz.com', street_address: '56 Hughey Cl', town: 'Mareeba', state: 'Queensland', country: 'Australia', postal_code: 4880, primary_phone: '(07) 4092 6735', secondary_phone: '0422 454 829')
contact2 = db[:contact].insert(email: 'littlesamurai@myfantasy.com', street_address: '65 Rankin St', town: 'Mareeba', state: 'Queensland', country: 'Australia', postal_code: 4880, primary_phone: '(07) 4095 4116', secondary_phone: nil)
contact3 = db[:contact].insert(email: 'emochick56@hotmail.com', street_address: '72 Ray Rd', town: 'Mareeba', state: 'Queensland', country: 'Australia', postal_code: 4880, primary_phone: '(07) 5555 5555', secondary_phone: nil)
contact4 = db[:contact].insert(email: 'me@iamme.com', street_address: '4 Gordon St', town: 'Malanda', state: 'Queensland', country: 'Australia', postal_code: 4873, primary_phone: '(07) 6666 6666', secondary_phone: nil)
contact5 = db[:contact].insert(email: 'bickboy@gmail.com', street_address: '11-14 Jaquillan St', town: 'Atherton', state: 'Queensland', country: 'Australia', postal_code: 4873, primary_phone: '(07) 7777 7777', secondary_phone: nil)

db[:funeral_director].where(:name => 'Jolly Jumping Jack Funerals').delete
db[:funeral_director] << {:name => 'Jolly Jumping Jack Funerals', :residential_contact_id => contact1, :mailing_contact_id => contact1}

db[:role] << {person_id: 1, type: 'reservee', residential_contact_id: contact1, mailing_contact_id: contact2}
db[:role] << {person_id: 2, type: 'next_of_kin', residential_contact_id: contact5, mailing_contact_id: contact4}
db[:role] << {person_id: 3, type: 'applicant', residential_contact_id: contact3}
db[:role] << {person_id: 1, type: 'deceased', residential_contact_id: contact2}
db[:role] << {person_id: 3, type: 'reservee', residential_contact_id: contact3, mailing_contact_id: contact3}

db[:allocation].insert(type: 'reservation', place_id: 7,  status: 'approved')
db[:allocation].insert(type: 'reservation', place_id: 8,  status: 'approved', location_description: 'Next to the big rock.', comments: 'Just some dummy comment text.')
db[:allocation].insert(type: 'interment', place_id: 8,  status: 'approved', funeral_director_id: 1, interment_date: (DateTime.now + 7), interment_type: 'coffin', comments: 'Call office prior burial.')
db[:allocation].insert(type: 'reservation', place_id: 13, status: 'approved')
db[:allocation].insert(type: 'interment', place_id: 13, status: 'approved', funeral_director_id: 1, interment_date: (DateTime.now + 3), interment_type: 'ashes', burial_requirements: 'On back please')
db[:allocation].insert(type: 'reservation', place_id: 15, status: 'deleted')
db[:allocation].insert(type: 'interment', place_id: 15, status: 'deleted', funeral_director_id: 1, interment_date: (DateTime.now + 10), interment_type: 'ashes', burial_requirements: 'To be provided')

db[:role_association] << {role_id: 1, allocation_id: 1}
db[:role_association] << {role_id: 1, allocation_id: 2}
db[:role_association] << {role_id: 3, allocation_id: 2}
db[:role_association] << {role_id: 2, allocation_id: 3}
db[:role_association] << {role_id: 4, allocation_id: 4}
db[:role_association] << {role_id: 5, allocation_id: 5}

db[:transaction] << {:allocation_id => 3, :receipt_no => '69242a'}
db[:transaction] << {:allocation_id => 5, :receipt_no => 72353}

db[:user] << {id: 'tomw', role: 'coordinator'}
db[:user] << {id: 'tatej', role: 'coordinator'}
db[:user] << {id: 'danielg', role: 'coordinator'}
db[:user] << {id: 'marar', role: 'coordinator'}
db[:user] << {id: 'adrians', role: 'coordinator'}
db[:user] << {id: 'megank', role: 'coordinator'}
db[:user] << {id: 'amandar', role: 'coordinator'}
db[:user] << {id: 'ttu', role: 'operator'}

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

# RSpec.configure do |conf|
#   conf.include Rack::Test::Methods
# end

# def app
#   ##
#   # You can handle all padrino applications using instead:
#   #   Padrino.application
#   Pilot.tap { |app|  }
# end
