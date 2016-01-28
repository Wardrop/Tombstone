module Rack
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
end