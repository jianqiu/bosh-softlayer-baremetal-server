module Bluemix::BM
  module Api
    module Controllers
      class BaseController < Sinatra::Base
        PUBLIC_URLS = %w(/info)

        include ApiHelper

        def initialize(*_)
          super
        end

        mime_type :tgz, 'application/x-compressed'

        def authenticate(user, password)
          config = Bluemix::BM::App.instance.config
          return true
          if [ config["credentials"]["user"], config["credentials"]["password"] ] == [user, password]
            true
          else
            false
          end
        end


        before do
          auth_provided = %w(HTTP_AUTHORIZATION X-HTTP_AUTHORIZATION X_HTTP_AUTHORIZATION).detect do |key|
            request.env.has_key?(key)
          end

          protected! if auth_provided || !PUBLIC_URLS.include?(request.path_info)
        end

        after { headers('Date' => Time.now.rfc822) } # As thin doesn't inject date

        configure do
          set(:show_exceptions, false)
          set(:raise_errors, false)
          set(:dump_errors, false)
        end

        error do
          exception = request.env['sinatra.error']
          msg = ["#{exception.class} - #{exception.message}:"]
          msg.concat(exception.backtrace)
          #@logger.error(msg.join("\n"))
          puts(msg.join("\n"))
          status(500)
        end
      end
    end
  end
end

