module Bluemix::BM
  module Api
    module ApiHelper

      def json_encode(payload)
        Yajl::Encoder.encode(payload)
      end

      def json_decode(payload)
        Yajl::Parser.parse(payload)
      end

      def protected!
        unless authorized?
          response['WWW-Authenticate'] = 'Basic realm="Bluemix Provision Server"'
          throw(:halt, [401, "Not authorized\n"])
        end
      end

      def authorized?
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        @auth.provided? && @auth.basic? && @auth.credentials && authenticate(*@auth.credentials)
      end

    end
  end
end
