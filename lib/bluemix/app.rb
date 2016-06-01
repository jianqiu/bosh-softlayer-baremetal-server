require 'bluemix/common/task_utils'
require 'bluemix/common/task_logger'
require 'bluemix/common/shell'
require 'bluemix/common/utils'
require 'bluemix/common/message'
require 'bluemix/softlayer/baremetal_utils'
require 'bluemix/jobs/base_job'
require 'bluemix/jobs/load_stemcell_job'
require 'bluemix/jobs/create_baremetal_job'
require 'bluemix/jobs/create_baremetal_dryrun_job'
require 'redis'

module Bluemix::BM

  class App

    class << self
      def instance
        @@instance
      end
    end


    attr_reader :config
    attr_reader :logger
    attr_reader :redis

    def initialize(config)
      @@instance = self
      @config = config
      @logger = Logger.new(STDOUT)
      redis_options = {
          :host     => config['redis']['address'],
          :port     => config['redis']['port'],
          :password => config['redis']['password'],
          :logger   => @logger
        }
      @redis = Redis.new( redis_options )
      
      Common::Utils.init
      Softlayer::BaremetalUtils.init
    end

  end
end

module Resque
  def redis
    Bluemix::BM::App.instance.redis
  end
end
