

module Bluemix::BM
  module Jobs 
    class LoadStemcellJob < BaseJob
      @queue = :normal

      def initialize( server, stemcell, netboot_image )
        @server = server 
        @stemcell = stemcell
        @netboot_image = netboot_image
      end

      def perform
        begin
          Common::TaskUtils.init_logger( @task_id )
          Common::TaskUtils.update_task_status( @task_id, "running" )
          server = @server
          File.open("#{task_dir}/server", 'w+') {|f| 
            f.write( { "id" => server['id'] }.to_yaml ) 
          }
          Bluemix::BM::App.instance.config["event_loger"].event_info( "Begin to load stemcell #{@stemcell} into bare metal #{server['hostname']}" )
          command = "#{App.instance.config['root_dir']}/scripts/install_node_xcat.sh -server_url http://#{App.instance.config['host']}:#{App.instance.config['port']} -blobstore_dir #{App.instance.config['blobstore_dir']} -node_id #{server['id']} -node_name #{server['hostname']} -stemcell #{@stemcell} -private_ip #{server['private_ip']}  -private_subnet #{server['private_subnet']} -private_netmask #{server['private_netmask']}  -private_gateway #{server['private_gateway']} -public_ip #{server['public_ip']} -public_subnet #{server['public_subnet']}  -public_netmask #{server['public_netmask']} -public_gateway #{server['public_gateway']} -root_passwd #{server['root_password']} -netboot_image #{@netboot_image} >> #{task_dir}/debug 2>&1"

          puts command 
          exit_code, _ = Common::Shell.run_command( command )
          if exit_code == 0 
          Bluemix::BM::App.instance.config["event_loger"].event_info( "Complete to load stemcell #{@stemcell} into bare metal #{server['hostname']}" )
            Softlayer::BaremetalUtils.update_state_loading2using( server["id"] )
            Common::TaskUtils.update_task_info( @task_id, { "status" => "completed", "end_time" => Time.now } )
          else
            Bluemix::BM::App.instance.config["event_loger"].event_info( "Failed to load stemcell #{@stemcell} into bare metal #{server['hostname']}" )
            Softlayer::BaremetalUtils.update_state_loading2failed( server["id"] )
            Common::TaskUtils.update_task_info( @task_id, { "status" => "failed", "end_time" => Time.now } )
          end
        rescue => e
          Bluemix::BM::App.instance.config["event_loger"].event_info( "Failed to load stemcell #{@stemcell} into bare metal #{server['hostname']}" )
          Common::TaskUtils.update_task_info( @task_id, { "status" => "failed", "end_time" => Time.now } )
          Bluemix::BM::App.instance.config["event_loger"].event_error( "Failed. Error #{e}, #{e.backtrace.join(", ")}" )
        ensure
          Common::TaskUtils.close_logger( @task_id )
        end
      
      end
      

    end
  end
end
