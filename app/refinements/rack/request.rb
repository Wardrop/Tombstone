module Tombstone
  # Rewrite Request#POST for reasons defined here: https://github.com/rack/rack/pull/749
  class Rack::Request
    def POST
      @_POST ||= begin
        hash = super
        if env['CONTENT_TYPE'] && env['CONTENT_TYPE'].match(%r{^application/json})
          body = request.body.read
          unless body.empty?
            hash.merge!(JSON.parse(body))
          end
          request.body.rewind
        end
        hash
      end
    end
  end
end
