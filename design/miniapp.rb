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
  p request
  content_type :json
  [
    {id: 12, title: 'Mr', surname: 'Blah', given_name: 'John'},
    {id: 25, title: 'Ms', surname: 'Baz', given_name: 'Mary'}
  ].to_json
end