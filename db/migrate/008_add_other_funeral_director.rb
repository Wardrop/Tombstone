Sequel.migration do
  up do
    self[:funeral_director].insert(:name => 'Other')
  end
end