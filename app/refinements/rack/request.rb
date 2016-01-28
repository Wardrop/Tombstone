module Tombstone
  # Rewrite Request#POST for reasons defined here: https://github.com/rack/rack/pull/749
  class Rack::Request
    def POST
      raise "Missing rack.input" if @env["rack.input"].nil?
      @env["rack.request.form_hash"] ||= {}

      if !(@env["rack.request.form_input"].equal? @env["rack.input"]) && (form_data? || parseable_data?)
        parsed_result = parse_multipart(env)
        if parsed_result
          @env["rack.request.form_hash"].merge! parsed_result
        else
          form_vars = @env["rack.input"].read

          # Fix for Safari Ajax postings that always append \0
          # form_vars.sub!(/\0\z/, '') # performance replacement:
          form_vars.slice!(-1) if form_vars[-1] == ?\0

          @env["rack.request.form_vars"] = form_vars
          @env["rack.request.form_hash"].merge! parse_query(form_vars)

          @env["rack.input"].rewind
        end
        @env["rack.request.form_input"] = @env["rack.input"]
      end

      @env["rack.request.form_hash"]
    end
  end
end