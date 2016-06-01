module Bluemix::BM
  module Common
    class TaskLogger

      def initialize( task_id )
        @config = Bluemix::BM::App.instance.config
        @event_log = File.open( File.join("#{@config['store_dir']}/tasks/#{task_id}", 'event'), "a+" )
      end

      def close()
        @event_log.close
      end

      def event_info( message) 
        event( "INFO", message )
      end

      def event_error( message) 
        event( "ERROR", message )
      end

      def event( level, message )
        puts "Log: #{level} -- #{message}\n"
        @event_log.write( "#{level} -- #{message}\n" )
        @event_log.flush
      end

    end
  end
end

