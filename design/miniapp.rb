require 'sinatra'
require 'sinatra/reloader'
require 'json'

get "/" do
  "Hello"
end

get "/person/:id" do
  content_type :json
  {id: 12, title: 'Mr', surname: 'Blah', given_name: 'John'}.to_json
end

get "/people" do
  p params
  content_type :json
  [
    {id: 12, title: 'Mr', surname: 'Blah', given_name: 'John'},
    {id: 25, title: 'Ms', surname: 'Baz', given_name: 'Mary'}
  ].to_json
end

get "/addresses" do
  content_type :json
  [
    {
      id: 5,
      street_address: '65 Rankin St',
      town: 'Mareeba',
      state: 'Queensland',  		postal_code: '4880',
  		primary_phone: '(07) 4043 4436',
  		secondary_phone: '0428 582 993'
    }, {
      id: 33,
      street_address: '45 Mabel St',
      town: 'Atherton',
      state: 'Queensland',  		postal_code: '4880',
  		primary_phone: '(07) 4043 4400',
  		secondary_phone: '1300 398 432'
    }
  ].to_json
end