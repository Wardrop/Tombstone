module Tombstone
  class Controller < Scorched::Controller
    include Helpers

    if ENV['RACK_ENV'] == 'development'
      config[:static_dir] = '../public'
    end

    render_defaults.merge!(
      layout: :"#{File.expand_path('views/layouts/application')}",
      outvar: '@_out_buf'
    )

    middleware << proc {
      use Rack::Lock
      use Rack::ResponsePadder
      use Rack::Session::Sequel, :db => Sequel::Model.db, :table_name => :session, :expire_after => 60 * 60 * 24 * 7
    }

    conditions[:logged_in] = proc { |bool| bool != session[:user_id].nil? }

    def document
      env['tombstone.document']
    end

    before do
      env['tombstone.document'] = {
        title: 'Tombstone',
        scripts: [],
        breadcrumb: true,
        banner: nil
      }

      # If the base URL is not hard-coded in the configuration, set it dynamically on the first request.
      CONFIG[:base_url] ||= URI.join(request.base_url, env['SCRIPT_NAME']).to_s
      document[:banner] = flash[:banner]
      User.current = env['tombstone.user'] = User.with_pk(session[:user_id]) || User.new(id: session[:user_id]) if session[:user_id]
      BaseModel.permissions = (env['tombstone.user'].role_permissions rescue nil)
    end

    after failed_condition: :logged_in, dispatched: false do
      if env['HTTP_ACCEPT'] && env['HTTP_ACCEPT'].include?('application/json')
        halt 401, 'You must login to use this application.'.to_json
      else
        flash[:banner] = 'error', 'You must login to use this application.'
        referrer = URI.escape(request.fullpath, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        redirect absolute("/login?referrer=#{referrer}"), status: 303
      end
    end

    error PermissionsError do |e|
      error_message = "Permissions error: #{e.message}"
      if request.content_type == 'application/json'
        halt 500, {errors: e.message}.to_json
      else
        halt 500, "Permissions error: #{e.message}"
      end
    end

    error StandardError do |e|
      if request.content_type == 'application/json'
        STDERR.puts "#{e.backtrace.first}: #{e.message} (#{e.class})", e.backtrace.drop(1).map{|s| "\t#{s}"}
        halt 500, {errors: e.message}.to_json
      else
        raise e
      end
    end

    # Implementation of `content_for` for ERB templates.
    render_defaults[:tilt][:outvar] = '@_out_buf'
    def content_for(key, &block)
      buffer = @_out_buf
      @_out_buf = ''
      content_blocks[key] << block.call
      @_out_buf = buffer
    end

    def yield_content(key, *args)
      return nil if content_blocks[key].empty?
      content_blocks[key].join
    end

    def content_blocks
      @content_blocks ||= Hash.new {|h,k| h[k] = [] }
    end
  end
end
