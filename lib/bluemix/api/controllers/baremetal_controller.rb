require 'bluemix/api/controllers/base_controller'

module Bluemix::BM
  module Api::Controllers
    class BaremetalController < BaseController

      # load the stemcell in the baremetal
      put '/baremetal/spec/:spec_name/:stemcell/?:netboot_image?' do
   
        begin
          manifest = Psych.load(request.body) #request.body.read
          image = params[:netboot_image] || Bluemix::BM::App.instance.config["default_image"] 
          server = Softlayer::BaremetalUtils.get_baremetal( params[:spec_name] )
          return Bluemix::BM::Common::Message.fail( { :message => "No available server found, please create new baremetal in the pool #{params[:spec_name]}" } ) if server.nil?
          task_id = Bluemix::BM::Common::TaskUtils.enqueue("worker_#{server["private_vlan_id"]}", Jobs::LoadStemcellJob, 'load stemcell', [server, params[:stemcell], image] )
          Common::TaskUtils.update_task_status( task_id, "running" )

        
          result = {
            "task_id" => task_id
          }
          Bluemix::BM::Common::Message.success( result )
        rescue => e
          Bluemix::BM::Common::Message.fail( { :message => "Error: #{e}" }, e )
        end
      end

      put '/baremetals/reboot/:id/:mode' do
        begin
          Softlayer::BaremetalUtils.reboot_baremetal( params[:id], params[:mode] )
          Bluemix::BM::Common::Message.success( {} )
        rescue => e
          Bluemix::BM::Common::Message.fail( { :message => "Error: #{e}" }, e )
        end
      end

      # create the baremetals in Softlayer, and put them in the "bm.state.new" pool
      post '/baremetals' do
        begin
          bm_specs = json_decode( request.body )
          puts "jimmy: #{bm_specs.to_yaml}"
          return Bluemix::BM::Common::Message.fail( { :message => "Please specify the baremetal specfication" } ) if bm_specs.nil?

          task_id = Bluemix::BM::Common::TaskUtils.enqueue("common", Jobs::CreateBaremetalJob, 'Create Baremetal', [bm_specs] )
          Common::TaskUtils.update_task_status( task_id, "running" )


          result = {
            "task_id" => task_id
          }
          Bluemix::BM::Common::Message.success( result )
        rescue => e
          Bluemix::BM::Common::Message.fail( { :message => "Error: #{e}" }, e )
        end
        
      end

      # create the baremetals in Softlayer by dryrun to verify the order
      post '/baremetals/dryrun' do
        begin
          bm_specs = json_decode( request.body )
          puts "jimmy: #{bm_specs.to_json}"
          return Bluemix::BM::Common::Message.fail( { :message => "Please specify the baremetal specfication" } ) if bm_specs.nil?

          task_id = Bluemix::BM::Common::TaskUtils.enqueue("common", Jobs::CreateBaremetalDryrunJob, 'Create Baremetal - dryrun', [bm_specs] )
          Common::TaskUtils.update_task_status( task_id, "running" )

          result = {
            "task_id" => task_id
          }
          Bluemix::BM::Common::Message.success( result )
        rescue => e
          Bluemix::BM::Common::Message.fail( { :message => "Error: #{e}" }, e )
        end

      end

      get '/baremetal/:id' do
        server = Softlayer::BaremetalUtils.get_baremetal_by_id( params[:id] )
        return Bluemix::BM::Common::Message.fail( { :message => "Server #{params[:id]} is not found" } ) if server.nil?
        Bluemix::BM::Common::Message.success( server )
      end

      delete '/baremetal/:id' do
        begin
          Softlayer::BaremetalUtils.update_state_using2new( params[:id] )
          Bluemix::BM::Common::Message.success( {} )
        rescue => e
          Bluemix::BM::Common::Message.fail( { :message => "Error: #{e}" }, e )
        end
      end

      put '/baremetal/:id/:state' do
        begin
          Softlayer::BaremetalUtils.update_state2( params[:id], params[:state] )
          Bluemix::BM::Common::Message.success( {} )
        rescue => e
          Bluemix::BM::Common::Message.fail( { :message => "Error: #{e}" }, e )
        end
      end

      get '/bms/:deployment' do
        begin
          servers = Softlayer::BaremetalUtils.get_baremetals( params[:deployment] )
          Bluemix::BM::Common::Message.success( servers )
        rescue => e
          Bluemix::BM::Common::Message.fail( { :message => "Error: #{e} Calls: #{e.backtrace.join("; ")}" } )
        end
      end
    end
  end
end
