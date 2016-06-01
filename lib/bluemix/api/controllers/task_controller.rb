require 'bluemix/api/controllers/base_controller'

module Bluemix::BM
  module Api::Controllers
    class TaskController < BaseController

      get '/tasks' do
        begin
          state = Common::TaskUtils.get_latest_tasks( params[:latest].to_i || 50 )
          Bluemix::BM::Common::Message.success( state )
        rescue => e
          Bluemix::BM::Common::Message.fail( { :message => "Error: #{e}" } )
        end
      end

      get '/task/:id/txt/:res_name' do
        info = Common::TaskUtils.get_task_txt_resource( params[:id], params[:res_name] )
        
        Bluemix::BM::Common::Message.success( info )
      end

      get '/task/:id/status' do
        status = Common::TaskUtils.get_task_status( params[:id] )
        
        Bluemix::BM::Common::Message.success( status )
      end

      get '/task/:id/json/:res_name' do
        
        info = Common::TaskUtils.get_task_resource( params[:id], params[:res_name] )
        result = {
          "info" => info
        }
        
        Bluemix::BM::Common::Message.success( result )
      end
    end
  end
end
