require 'bluemix/api/controllers/base_controller'

module Bluemix::BM
  module Api::Controllers
    class SoftlayerController < BaseController

      get '/sl/packages' do
        begin
          packages = Softlayer::BaremetalUtils.get_packages
          Bluemix::BM::Common::Message.success( packages )
        rescue => e
          return Bluemix::BM::Common::Message.fail( { :message => "Failed to retrieve Softlayer packages" } )
        end         
      end

      get '/sl/package/:pkg_id/options' do
        begin
          options = Softlayer::BaremetalUtils.get_package_options(params[:pkg_id])
          Bluemix::BM::Common::Message.success( options )
        rescue => e
          return Bluemix::BM::Common::Message.fail( { :message => "Failed to retrieve options for Softlayer package #{params[:pkg_id]}" } )
        end
      end

    end
  end
end
