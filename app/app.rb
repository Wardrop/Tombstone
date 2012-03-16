
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
    
      set :config, eval(File.read(File.expand_path('../config.rb', __FILE__)))
      Tombstone::Permissions.map = config[:roles]
      Tombstone::LDAP.servers = config[:ldap][:servers]
      Tombstone::LDAP.domain = config[:ldap][:domain]
      Tombstone::LDAP.logger = log

      Tombstone::Notification.config = config[:notification]
      Tombstone::Notification.general = config[:general]

    end
    
    before do
      if request.path_info != url(:login) && session[:user].nil?
        flash[:banner] = 'error', 'You must login to use this application.'
        redirect url(:login)
      end
      
      @document = {
        title: 'Tombstone',
        scripts: [],
        breadcrumb: true,
        banner: flash[:banner]
      }
      # BaseModel.inherited.each { |m| m.include PermissionsProxy; m.user = sessions[:user] }
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
          session[:user] = user
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
