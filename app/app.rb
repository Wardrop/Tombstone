
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
      use Rack::Session::Sequel, :db => Sequel::Model.db, :table_name => :session, :expire => 60 * 60 * 24 * 7
    
      set :config, eval(File.read(File.expand_path('../config.rb', __FILE__)))
      Tombstone::Permissions.map = config[:roles]
      Tombstone::LDAP.servers = config[:ldap][:servers]
      Tombstone::LDAP.domain = config[:ldap][:domain]
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
    end
    
    get :index do
      render :index
    end
    
    get :login do
      render 'login'
    end
    
    post :login do
      redirect :index if session[:authenticated]
      begin
        user_id = params['username'].split('\\')[1] || params['username'].split('@')[0] || params['username']
        user = User.with_pk(user_id) || User.new(id: user_id)
        if user.authenticate(params['password'])
          flash[:banner] = 'success', "You have been logged in successfully."
          session[:user] = user
          redirect url(:index)
        else
          @document[:banner] = 'error', "Could not login as: #{params['username']}."
          prepare_form(render('login'), values: params.reject{|k,v| k == 'password'})
        end
      rescue => e
        @document[:banner] = 'error', e.message
        prepare_form(render('login'), values: params.reject{|k,v| k == 'password'})
      end
    end
    
    get :logout do
      session[:user] = nil
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
