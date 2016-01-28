Sequel.migration do
  up do 
    add_column :contact, :country, :nvarchar, :size => 64
    add_column :person, :middle_name, :nvarchar, :size => 40
    self['UPDATE person SET middle_name = middle_initials']
    drop_column :person, :middle_initials
    
    self[:contact].delete
    id = self[:contact].insert(street_address: '4 Bell Lane', town: '', state: 'Gordonvale', postal_code: 4865, primary_phone: '(07) 4056 1627', secondary_phone: '(07) 4056 3389')
    self[:funeral_director].insert(:name => 'BJ Brady Funeral Directors', :mailing_contact_id => id)
    id = self[:contact].insert(street_address: '18 Scullen Avenue', town: 'Innisfail', state: '', postal_code: 4860, primary_phone: '(07) 4061 6806', secondary_phone: '(07) 4061 3383')
    self[:funeral_director].insert(:name => "Black's Funerals", :mailing_contact_id => id)
    id = self[:contact].insert(email: 'reyad@cairnscrem.com.au', street_address: 'PO Box 7058', town: 'Cairns', state: 'QLD', postal_code: 4870, primary_phone: '(07) 4054 5400', secondary_phone: '(07) 4054 5422')
    self[:funeral_director].insert(:name => "Burkin Svendsen's Funeral Directors", :mailing_contact_id => id)
    id = self[:contact].insert(street_address: 'PO Box 114', town: 'Earville', state: 'QLD', postal_code: 4880, primary_phone: '(07) 4036 1888', secondary_phone: '(07) 4036 2619')
    self[:funeral_director].insert(:name => 'Cairns Crematorium and Funeral Home', :mailing_contact_id => id)
    id = self[:contact].insert(street_address: "PO Box 485", town: "Manunda", state: "QLD", postal_code: "4870", primary_phone: "(07) 4053 7499", secondary_phone: "(07) 4053 7046")
    self[:funeral_director].insert(:name => 'Cairns Funeral Directors', :mailing_contact_id => id)
    id = self[:contact].insert(street_address: "PO Box 851", town: "Edge Hill", state: "QLD", postal_code: "4870", primary_phone: "(07) 4032 5503", secondary_phone: "(07) 4032 5507")
    self[:funeral_director].insert(:name => 'Cairns Monumental', :mailing_contact_id => id)
    id = self[:contact].insert(email: "paul@crimminsfunerals.com", street_address: "PO Box 985", town: "Mossman", state: "QLD", postal_code: "4873", primary_phone: "(07) 4098 2655", secondary_phone: "(07) 3259 8563")
    self[:funeral_director].insert(:name => 'Crimmins Funerals', :mailing_contact_id => id)
    id = self[:contact].insert(street_address: "PO Box 277", town: "Mareeba", state: "QLD", postal_code: "4880", primary_phone: "4092 7311", secondary_phone: "4092 7411")
    self[:funeral_director].insert(:name => 'Eales Family Funeral Service', :mailing_contact_id => id)
    id = self[:contact].insert(email: "reyad@cairnscrem.com.au", street_address: "PO Box 825", town: "Bungalow", state: "QLD", postal_code: "4870", primary_phone: "(07) 4035 6142", secondary_phone: "(07) 4036 2619")
    self[:funeral_director].insert(:name => 'Far Northern Funerals', :mailing_contact_id => id)
    id = self[:contact].insert(street_address: "PO Box 1191", town: "Bundaberg", state: "QLD", postal_code: "4670", primary_phone: "(07) 4151 3357", secondary_phone: "(07) 4153 1697")
    self[:funeral_director].insert(:name => 'FC Brown & Co Funeral Directors', :mailing_contact_id => id)
    id = self[:contact].insert(email: "cchaffey@bigpond.net.au", street_address: "PO Box 297", town: "Atherton", state: "QLD", postal_code: "4883", primary_phone: "(07) 4091 2147", secondary_phone: "(07) 4091 3576")
    self[:funeral_director].insert(:name => 'Guilfoyles Funeral Service', :mailing_contact_id => id)
    id = self[:contact].insert(street_address: "2 Martinez Avenue", town: "Townsville", state: "QLD", postal_code: "4810", primary_phone: "(07) 4779 4744", secondary_phone: "(07) 4779 5480")
    self[:funeral_director].insert(:name => 'Morleys Funerals', :mailing_contact_id => id)
    id = self[:contact].insert(street_address: "PO Box 485M", town: "Manunda", state: "QLD", postal_code: "4870", primary_phone: "(07) 4053 7499", secondary_phone: "(07) 4035 2611")
    self[:funeral_director].insert(:name => 'Newhaven Funerals', :mailing_contact_id => id)
    id = self[:contact].insert(street_address: "PO Box 996", town: "Manunda", state: "QLD", postal_code: "4870", primary_phone: "(07) 4053 7799", secondary_phone: "(07) 4053 1934")
    self[:funeral_director].insert(:name => 'Straight Cremation Funerals', :mailing_contact_id => id)
    id = self[:contact].insert(street_address: "PO Box 985", town: "Mossman", state: "QLD", postal_code: "4873", primary_phone: "(07) 4031 5566", secondary_phone: "(07) 3259 8563")
    self[:funeral_director].insert(:name => 'Trinity Funerals', :mailing_contact_id => id)
  end
  
  down do
    add_column :person, :middle_initials, :nvarchar, :size => 3
    self.run 'UPDATE person SET middle_initials = middle_name'
    drop_column :contact, :country
    drop_column :person, :middle_name
  end
end