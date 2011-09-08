require "sinatra"
require "htmlentities"
require "nokogiri"
require "logger"
require "mysql2"
Dir.glob('./lib/**/*.rb') { |file| require file }

module Tombstone
  class Main < Sinatra::Base
    
    configure do
      set :app_file, __FILE__
      set :config, eval(File.read('config.rb'))
      set :log, Logger.new(settings.config[:log_file])
      use Rack::Session::Pool, :expire => 900
      use Rack::NTLM
      HTTPI.log = false
      Savon.log = false
    end

    configure :development do
      set :log, Logger.new(STDOUT)
    end
    
    get "/" do
      "Welcome to Tombstone!"
    end
    
  end
end