
# Dir.glob(File.join(File.dirname(__FILE__), 'lib/*/**/*.rb')) { |f| require f }

module Tombstone
  VERSION = '1.3.3'
  
  class << self
    attr_accessor :config
  end
  
  # Middleware to pad responses to avoid IE's buggy and annoying friendly error message handling.
  class ResponsePadder
    def initialize(app)
      @app = app       
    end                
  
    def call(env)
      response = @app.call(env)
      if Array === response[2] && !response[2].empty?
        total_length = response[2].reduce(0) { |m,v| m + v.length }
        if total_length <= 512
          response[2] << ''.ljust(513 - total_length)
          response[1]['Content-Length'] = '513'
        end
      end
      response
    end                
  end 
  
  class App < Padrino::Application
    register Padrino::Rendering
    register Padrino::Mailer
    register Padrino::Helpers

    configure do
      logger = Logger.new(STDOUT, 'weekly')
      logger.level = Logger::WARN
      disable :show_exceptions
      use Rack::Session::Sequel, :db => Sequel::Model.db, :table_name => :session, :expire_after => 60 * 60 * 24 * 7
      use Rack::Lock
      use ResponsePadder
      
      set :config, eval(File.read(File.expand_path('../config.rb', __FILE__)))
      Tombstone.config = config
      Mail.defaults do
        delivery_method Tombstone.config[:email][:delivery_method]
      end
      Permissions.map = config[:roles]
      LDAP.servers = [*config[:ldap][:servers]]
      LDAP.domain = config[:ldap][:domain]
      LDAP.logger = logger

      if environment != :spec
        Models = ObjectSpace.each_object(::Class).to_a.select { |k| k < BaseModel || k == BaseModel }.each do |m|
          if m.name
            model_name = m.name.split('::').last
            m.send(:include, ModelPermissions.const_get(model_name)) if ModelPermissions.const_defined? model_name
          end
        end
      end
    end
    
    before do
      if request.path_info != url(:login) && request.path_info != url(:logout) && session[:user_id].nil?
        if request.accept.include?(mime_type :json)
          halt 401, 'You must login to use this application.'.to_json
        else
          flash[:banner] = 'error', 'You must login to use this application.'
          referrer = URI.escape(request.fullpath, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
          redirect("#{url(:login)}?referrer=#{referrer}", 303)
        end
      end
      
      @document = {
        title: 'Tombstone',
        scripts: [],
        breadcrumb: true,
        banner: flash[:banner]
      }
      
      User.current = @user = User.with_pk(session[:user_id]) || User.new(id: session[:user_id]) if session[:user_id]
      BaseModel.permissions = (@user.role_permissions rescue nil)

      if request.content_type && request.content_type.match(%r{^application/json})
        body = request.body.read
        unless body.empty?
          params.merge!(JSON.parse(body))
        end
        request.body.rewind
      end
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
          redirect(params['referrer'] || url(:index))
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
    
    get :test do
      halt 404, "Yay"
    end

    error StandardError do
      if env['sinatra.error']
        if response.content_type.index(mime_type :json) == 0 || response.content_type.index(mime_type :text) == 0
          halt 500, {errors: "Server error encountered: #{env['sinatra.error'].message}"}.to_json
        else
          raise env['sinatra.error']
        end
      end
    end
  end
end
