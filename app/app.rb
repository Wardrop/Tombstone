
# Dir.glob(File.join(File.dirname(__FILE__), 'lib/*/**/*.rb')) { |f| require f }

module Tombstone
  VERSION = 0.6
  
  class App < Padrino::Application
    register Padrino::Rendering
    register Padrino::Mailer
    register Padrino::Helpers
    
    configure :spec, :production do
      set :log, Logger.new(nil)
    end
    configure :development do 
      set :log, Logger.new(STDOUT)
    end
    configure do
      disable :show_exceptions
      use Rack::Session::Sequel, :db => Sequel::Model.db, :table_name => :session, :expire_after => 60 * 60 * 24 * 7
      use Rack::Lock
      
      set :config, eval(File.read(File.expand_path('../config.rb', __FILE__)))

      Permissions.map = config[:roles]
      LDAP.servers = config[:ldap][:servers]
      LDAP.domain = config[:ldap][:domain]
      LDAP.logger = log

      Notification.config = config[:notification]
      Notification.general = config[:general]

      Models = ObjectSpace.each_object(::Class).to_a.select { |k| k < BaseModel || k == BaseModel }.each do |m|
        if m.name
          model_name = m.name.split('::').last
          m.send(:include, ModelPermissions.const_get(model_name)) if ModelPermissions.const_defined? model_name
        end
      end
    end
    
    before do
      if request.path_info != url(:login) && request.path_info != url(:logout) && session[:user_id].nil?
        flash[:banner] = 'error', 'You must login to use this application.'
        redirect url(:login)
      end
      
      @document = {
        title: 'Tombstone',
        scripts: [],
        breadcrumb: true,
        banner: flash[:banner]
      }
      @user = User.with_pk(session[:user_id])
      BaseModel.permissions = Permissions.new((@user.role rescue nil))
    end
    
    get :permissions_test do
      Tombstone::Reservation.new.save(validate: false).inspect
    end
    
    get :index do
      @calendar = Calendar.new
      render :index
    end
    
    get :login do
      render 'login'
    end
    
    post :login do
      redirect :index if session[:authenticated]
      user_id = LDAP.parse_username(params['username'])
      user = User.with_pk(user_id) || User.new(id: user_id)
      begin
        if user.authenticate(params['password'])
          flash[:banner] = 'success', "You have been logged in successfully."
          session[:user_id] = user_id
          session[:ldap] = user.ldap.user_details
          redirect url(:index)
        else
          @document[:banner] = 'error', 'Invalid username or password.'
        end
      rescue => e
        @document[:banner] = 'error', e.message
      end
      prepare_form(render('login'), values: params.reject{|k,v| k == 'password'})
    end
    
    get :logout do
      session.clear
      p 'dog'
      flash[:banner] = 'success', 'You have been logged out successfully.'
      redirect url(:login)
    end
    
    error 500 do
      if response.content_type.index(mime_type :json) == 0
        halt 500, {success: false, exception: env['sinatra.error'].message}.to_json
      else
        raise env['sinatra.error'] if env['sinatra.error']
      end
    end
  
  end
end
