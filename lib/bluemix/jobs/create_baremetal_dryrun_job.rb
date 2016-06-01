

module Bluemix::BM
  module Jobs 
    class CreateBaremetalDryrunJob < BaseJob
      @queue = :normal

      def initialize( bm_specs )
        @bm_specs = bm_specs 
      end

      def perform
        begin
          Common::TaskUtils.init_logger( @task_id )
          Common::TaskUtils.update_task_status( @task_id, "running" )
          needed_bm_specs = Softlayer::BaremetalUtils.get_missed_baremetals( @bm_specs )
          orders = Softlayer::BaremetalUtils.create_baremetals( needed_bm_specs, false )

          succ_orders = orders.map{ |order| [order[0], order[3]] if order[1] == 1 }.compact

          Common::TaskUtils.update_task_info( @task_id, { "status" => "completed", "end_time" => Time.now } )
          Bluemix::BM::App.instance.config["event_loger"].event_info( "Successful!!" )
        rescue => e 
          puts "err: #{e.backtrace}"
          Common::TaskUtils.update_task_info( @task_id, { "status" => "failed", "end_time" => Time.now } )
          Bluemix::BM::App.instance.config["event_loger"].event_error( "Failed. Error #{e}, #{e.backtrace.join(", ")}" )
        ensure
          Common::TaskUtils.close_logger( @task_id )
        end
      end
      

    end
  end
end
