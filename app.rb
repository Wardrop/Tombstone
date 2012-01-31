require "bundler/setup"
Bundler.require(:default)

require "logger"
require "json"

Dir.glob('./lib/**/*.rb') { |file| require file }

module Tombstone
  class Main < Sinatra::Base
    
    configure do
      config_hash = eval(File.read('./config.rb'))
      set :config, config_hash[:default]
      if(config_hash[settings.environment])
        settings.config.merge!(config_hash[settings.environment])
      end
      set :log, Logger.new(settings.config[:log_file])
      use Rack::Session::Pool, :expire => 900
    end
    
    helpers Helpers

    configure :development do
      set :log, Logger.new(STDOUT)
    end
    
    configure do
      DB = Sequel.connect({adapter: 'tinytds'}.merge(settings.config[:db]))
    end
    
    before do
      @document = {
        title: 'Untitled',
        head: '',
        scripts: [
          'vendor/underscore.js',
          'vendor/backbone.js',
          'helpers.js',
          'models.js',
          'collections.js'
        ],
        script_templates: []
      }
    end
    
    get "/" do
      erb :index
    end
    
    get "/find" do
      @results = Reservation.all
      erb :find
    end
        
    get "/reservation" do
      @root_places = Place.with_child_count.filter(:parent_id => nil).order(:name).naked.all
      erb :reservation
    end
    
    post "/reservation", :provides => 'json' do
      content_type :json
      response = {success: false, form_errors: {}}
      response[:form_errors]['reservee'] = "Reservee must be added to reservation." unless params['reservee'].is_a? Hash
      #response[:form_errors]['next_of_kin'] = "Next of Kin must be added to reservation." unless params['next_of_kin'].is_a? Hash
      #response[:form_errors]['applicant'] = "Applicant must be added to reservation." unless params['applicant'].is_a? Hash
      response[:form_errors]['place'] = "A place must be selected." unless params['place']
      
      if response[:form_errors].empty?
        Reservation.db.transaction do
          
          roles = {}
          params.select { |k,v| ['reservee', 'next_of_kin', 'applicant'].include? k}.each do |name, data|
            if data['person']['id']
              party = Party[data['person']['id']]
              if party.nil?
                response[:form_errors][name] = "The selected '#{name.capitalize}' does not exist."
                raise Sequel::Rollback
              end
            else
              party = Party.new.set(data['person'])
              if party.is_valid?
                party.save
              else
                response[:form_errors][name] = party.errors
                raise Sequel::Rollback
              end
            end
            
            if data['residential_address']['id']
              res_address = Address[data['residential_address']['id']]
              if res_address.nil?
                response[:form_errors][name] = "The selected address for the selected '#{name.capitalize}' does not exist."
                raise Sequel::Rollback
              end
            else
              res_address = Address.new.set(data['residential_address'])
              if res_address.is_valid?
                res_address.save
              else
                response[:form_errors][name] = res_address.errors
                raise Sequel::Rollback
              end
            end
            
            role = Role.new.set({type: (name == 'reservee' ? 'reservee' : 'contact') , party: party, residential_address: res_address})
            if role.valid?
              role.save
              roles[name] = role
            else
              response[:form_errors][name] = role.errors
              raise Sequel::Rollback
            end
          end
          
          Relationship.new.set({source_role: roles['reservee'], target_role: roles['next_of_kin']}).save
          Relationship.new.set({source_role: roles['reservee'], target_role: roles['applicant']}).save
          
          place = Place[params['place']]
          if place.nil?
            response[:form_errors]['place'] = "The selected place does not exist."
            raise Sequel::Rollback
          end
          
          reservation = Reservation.new.set({place: place, reservee: roles['reservee']})
          if reservation.valid?
            reservation.save
          else
            response[:form_errors].merge!(reservation.errors)
            raise Sequel::Rollback
          end
          
          response[:success] = true
        end
      end
      
      response.to_json
    end
    
    get "/places", :provides => 'json' do
      content_type :json
      Place.with_child_count.filter(:parent_id => params[:parent_id]).order(:name).naked.all.to_json
    end
    
    get "/places/:parent_id", :provides => 'json' do
      content_type :json
      Place.filter(:parent_id => params[:parent_id]).order(:name).naked.all.to_json
    end  
    
    get "/person/:id", :provides => 'json' do
      content_type :json
      Party.filter(:id => params[:id]).naked.all.to_json
    end

    get "/people", :provides => 'json' do
      content_type :json
      filter = params.reject{ |k,v| !v || v.empty? || v == 'null'}.symbolize_keys!
      Party.filter(filter).naked.all.to_json
    end

    get "/addresses", :provides => 'json' do
      content_type :json
      Party.select_all(:address).distinct.filter(:party__id => params[:party_id]).
        join(:role, :role__party_id => :party__id).
        join(:address, :address__id => [:role__residential_address_id, :role__mailing_address_id])
        .naked.all.to_json
    end
    
  end
end

Dir.glob('./models/**/*.rb') { |file| require file }