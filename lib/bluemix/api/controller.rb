require 'bluemix/api/controllers/baremetal_controller'
require 'bluemix/api/controllers/task_controller'
require 'bluemix/api/controllers/info_controller'
require 'bluemix/api/controllers/misc_controller'
require 'bluemix/api/controllers/stemcell_controller'
require 'bluemix/api/controllers/softlayer_controller'


module Bluemix::BM
  module Api
    class Controller < Sinatra::Base
      use Controllers::BaremetalController
      use Controllers::TaskController
      use Controllers::InfoController
      use Controllers::MiscController
      use Controllers::SoftlayerController
      use Controllers::StemcellController
    end
  end
end
