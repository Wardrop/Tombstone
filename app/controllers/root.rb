module Tombstone
  class Root < Controller
    get '/' do
      @calendar = Calendar.new
      render :index
    end

    get '/login' do
      render :login
    end

    post '/login' do
      redirect(:index, status: 303) if session[:authenticated]
      user_id = LDAP.parse_username(request.POST['username'])
      user = User.with_pk(user_id) || User.new(id: user_id)
      begin
        if user.authenticate(request.POST['password'])
          flash[:banner] = 'success', "You have been logged in successfully."
          session[:user_id] = user_id
          session[:ldap] = user.ldap.user_details
          redirect request.POST['referrer'] || absolute('/'), status: 303
        else
          document[:banner] = 'error', 'Invalid username or password.'
        end
      rescue => e
        document[:banner] = 'error', e.message
      end
      prepare_form(render(:login), values: request.POST.reject{|k,v| k == 'password'})
    end

    get '/logout' do
      session.clear
      flash[:banner] = 'success', 'You have been logged out successfully.'
      redirect absolute('/login'), status: 303
    end
  end
end
