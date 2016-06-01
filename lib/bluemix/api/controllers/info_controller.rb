require 'bluemix/api/controllers/base_controller'

module Bluemix::BM
  module Api::Controllers
    class InfoController < BaseController

      get '/info' do
        status = {
          'name' => "Bluemix Provision Server",
          'version' => "0.1"
        }
        Bluemix::BM::Common::Message.success( status )
      end
    end
  end
end
