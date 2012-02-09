require "bundler/setup"
Bundler.require(:default)

require "logger"
require "json"

Dir.glob('./lib/**/*.rb') { |file| require file }

module Tombstone
  class Main < Sinatra::Base
    
    helpers Helpers
    
    configure do
      config = eval(File.read('./config.rb'))
      set :config, config.for_environment(settings.environment)
      set :log, Logger.new(settings.config[:log_file])
      use Rack::Session::Pool, :expire => 900
    end

    configure :development do
      set :log, Logger.new(STDOUT)
    end
    
    configure do
      DB = Sequel.connect({adapter: 'tinytds'}.merge(settings.config[:db]))
    end
    
    before do
      @document = {
        title: 'Tombstone',
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
      @records = Allocation.filter(type: 'reservation').all
      erb :find
    end
        
    get "/reservation/new" do
      @root_places = Place.with_child_count.filter(:parent_id => nil).order(:name).naked.all
      erb :'reservation/new'
    end
    
    get "/reservation/view/:id" do
      @reservation = Allocation.with_pk([params[:id], 'reservation'])
      if @reservation
        erb :'reservation/view'
      else
        erb :'reservation/not_found' 
      end
    end
    
    post "/reservation", :provides => 'json' do
      content_type :json
      response = {success: false, form_errors: {}}
      response[:form_errors]['reservee'] = "Reservee must be added to reservation." unless params['reservee'].is_a? Hash
      #response[:form_errors]['next_of_kin'] = "Next of Kin must be added to reservation." unless params['next_of_kin'].is_a? Hash
      #response[:form_errors]['applicant'] = "Applicant must be added to reservation." unless params['applicant'].is_a? Hash
      response[:form_errors]['place'] = "A place must be selected." unless params['place']
      
      if response[:form_errors].empty?
        Allocation.db.transaction do
          
          roles = {}
          params.select { |k,v| ['reservee', 'applicant'].include? k}.each do |name, data|
            if data['person']['id']
              person = Person[data['person']['id']]
              if person.nil?
                response[:form_errors][name] = "The selected '#{name.capitalize}' does not exist."
                raise Sequel::Rollback
              end
            else
              person = Person.new.set(data['person'])
              if person.is_valid?
                person.save
              else
                response[:form_errors][name] = person.errors
                raise Sequel::Rollback
              end
            end
            
            if data['residential_contact']['id']
              res_contact = Contact[data['residential_contact']['id']]
              if res_contact.nil?
                response[:form_errors][name] = "The selected contact for the selected '#{name.capitalize}' does not exist."
                raise Sequel::Rollback
              end
            else
              res_contact = Contact.new.set(data['residential_contact'])
              if res_contact.is_valid?
                res_contact.save
              else
                response[:form_errors][name] = res_contact.errors
                raise Sequel::Rollback
              end
            end
            
            role = Role.new.set({type: name, person: person, residential_contact: res_contact})
            if role.valid?
              role.save
              roles[name] = role
            else
              response[:form_errors][name] = role.errors
              raise Sequel::Rollback
            end
          end
          
          place = Place[params['place']]
          if place.nil?
            response[:form_errors]['place'] = "The selected place does not exist."
            raise Sequel::Rollback
          end
          
          allocation = Allocation.new.set({type: 'reservation', place: place})
          if allocation.valid?
            allocation.save
          else
            response[:form_errors].merge!(allocation.errors)
            raise Sequel::Rollback
          end

          roles.each do |type, role|
            role.add_allocation(allocation)
          end
          
          response[:success] = true
        end
      end
      
      response.to_json
    end
    
    get "/places/:parent_id", :provides => 'json' do
      content_type :json
      Place.with_child_count.filter(:parent_id => params[:parent_id]).order(:name).naked.all.to_json
    end
    # 
    # get "/places/:parent_id", :provides => 'json' do
    #   content_type :json
    #   Place.filter(:parent_id => params[:parent_id]).order(:name).naked.all.to_json
    # end
    
    get "/places/next_available/:parent_id", :provides => 'json' do
      content_type :json
      next_available = Place.with_pk(params[:parent_id]).next_available
      ancestors = next_available.ancestors(params[:parent_id])
      chain = ancestors.reverse.push(next_available)
      
      result = []
      chain.each do |p|
        place = p.values
        place[:siblings] = Place.with_child_count.filter(:parent_id => place[:parent_id]).order(:id).naked.all
        result << place
      end
      result.to_json
    end
    
    get "/places/ancestors", :provides => 'json' do
      content_type :json
      Place.with_child_count.filter(:parent_id => params[:parent_id]).order(:name).naked.all.to_json
    end
    
    get "/person/:id", :provides => 'json' do
      content_type :json
      Person.filter(:id => params[:id]).naked.all.to_json
    end

    get "/people", :provides => 'json' do
      content_type :json
      filter = params.reject{ |k,v| !v || v.empty? || v == 'null'}.symbolize_keys!
      Person.filter(filter).naked.all.to_json
    end

    get "/contacts", :provides => 'json' do
      content_type :json
      Person.select_all(:contact).distinct.filter(:person__id => params[:person_id]).
        join(:role, :role__person_id => :person__id).
        join(:contact, :contact__id => [:role__residential_contact_id, :role__mailing_contact_id])
        .naked.all.to_json
    end
    
  end
end

Dir.glob('./models/**/*.rb') { |file| require file }