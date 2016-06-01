
module Bluemix::BM
  module Common
    class Message

      def self.success( data = nil )
        result = {
          :status => 200,
          :data => data
        }
        Yajl::Encoder.encode( result )
      end

      def self.fail( data = nil, e = nil )
        data.merge!({
          :backtrace => e.backtrace
        }) if e
        result = {
          :status => 300,
          :data => data
        }
        Yajl::Encoder.encode( result )
      end


    end
  end
end

