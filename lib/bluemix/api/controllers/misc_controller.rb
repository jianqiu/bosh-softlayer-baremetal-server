require 'bluemix/api/controllers/base_controller'

module Bluemix::BM
  module Api::Controllers
    class MiscController < BaseController

      get '/login/:username/:password' do
        if ["admin", "admin"] == [ params[:username], params[:password] ]
           Bluemix::BM::Common::Message.success()
        else 
           Bluemix::BM::Common::Message.fail( { :message => "username or password is incorrect!" } ) 
        end
      end
    end
  end
end
