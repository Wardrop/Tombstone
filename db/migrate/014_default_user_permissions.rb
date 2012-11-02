Sequel.migration do
  up do
    self[:user].insert(:id => 'marar', :role => 'coordinator')
    self[:user].insert(:id => 'tomw', :role => 'coordinator')
    self[:user].insert(:id => 'danielg', :role => 'coordinator')
    self[:user].insert(:id => 'tatej', :role => 'coordinator')
    self[:user].insert(:id => 'adrians', :role => 'coordinator')
    self[:user].insert(:id => 'megank', :role => 'coordinator')
    self[:user].insert(:id => 'amandar', :role => 'coordinator')
    self[:user].insert(:id => 'ttu', :role => 'operator')
  end
  
  down do
    self[:user].delete
  end
end