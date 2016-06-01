require 'remote_lock'

module Bluemix::BM
  module Common
    class Utils

      def self.init
        redis = Bluemix::BM::App.instance.redis
        @@lock = RemoteLock.new(RemoteLock::Adapters::Redis.new(redis))
        @@mutex = Mutex.new
      end

      def self.do_synchronize
        @@lock.synchronize("bluemix.bm.lock") do
#        @@mutex.synchronize do
          yield
        end
      end

    end
  end
end

