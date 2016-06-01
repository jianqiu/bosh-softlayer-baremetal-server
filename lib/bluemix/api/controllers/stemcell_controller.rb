require 'bluemix/api/controllers/base_controller'

module Bluemix::BM
  module Api::Controllers
    class StemcellController < BaseController

      get '/stemcells' do
        begin
          config = Bluemix::BM::App.instance.config
          stemcell_dir = config["blobstore_dir"]
          stemcells = Dir["#{stemcell_dir}/*"].map { |stemcell|
            File.basename( stemcell ) 
          } 
          Bluemix::BM::Common::Message.success( stemcells )
        rescue => e
          Bluemix::BM::Common::Message.fail( { :message => "Error: #{e}" } )
        end
      end

      get '/stemcells/download/:name' do
        begin
          send_file "#{App.instance.config['blobstore_dir']}/#{params[:name]}", :filename => params[:name], :type => 'Application/octet-stream'
        rescue => e
          Bluemix::BM::Common::Message.fail( { :message => "Error: #{e}" } )
        end
      end

    end
  end
end
