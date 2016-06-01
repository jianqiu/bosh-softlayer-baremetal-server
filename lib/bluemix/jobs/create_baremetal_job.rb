

module Bluemix::BM
  module Jobs 
    class CreateBaremetalJob < BaseJob
      @queue = :normal

      def initialize( bm_specs )
        @bm_specs = bm_specs 
      end

      def perform
        begin
          Common::TaskUtils.init_logger( @task_id )
          Common::TaskUtils.update_task_status( @task_id, "running" )
          needed_bm_specs = Softlayer::BaremetalUtils.get_missed_baremetals( @bm_specs )
          orders = Softlayer::BaremetalUtils.create_baremetals( needed_bm_specs )

          succ_orders = orders.map{ |order| [order[0], order[3]] if order[1] == 1 }.compact

          Softlayer::BaremetalUtils.wait_baremetals_ready( @bm_specs["deployment"], succ_orders )

          names = succ_orders.map{|node| node[0]}.join( " " )
          Bluemix::BM::App.instance.config["event_loger"].event_info( "Begin to make dhcp for #{names}" )
          command = "#{App.instance.config['root_dir']}/xcat/scripts/makedhcp.sh #{App.instance.config['root_dir']}/xcat/scripts/dhcpd.conf #{names} >> #{task_dir}/debug 2>&1"
          exit_code, _ = Common::Shell.run_command( command )
          Bluemix::BM::App.instance.config["event_loger"].event_info( "Make dhcp successfully" )
 
          Common::TaskUtils.update_task_info( @task_id, { "status" => "completed", "end_time" => Time.now } )
          Bluemix::BM::App.instance.config["event_loger"].event_info( "Order bare metals successfully!!" )
        rescue => e 
          Common::TaskUtils.update_task_info( @task_id, { "status" => "failed", "end_time" => Time.now } )
          Bluemix::BM::App.instance.config["event_loger"].event_error( "Failed. Error #{e}, #{e.backtrace.join(", ")}" )
        ensure
          Common::TaskUtils.close_logger( @task_id )
        end
      end
      

    end
  end
end
