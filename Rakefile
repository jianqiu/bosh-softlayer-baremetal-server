require "resque/tasks"

require 'erb'
require 'rubygems'
require 'bundler/setup'
require 'yaml'
require 'optparse'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')
require 'bluemix'
require 'bluemix/app'

config_file = nil
index = nil
erb = false

opts = OptionParser.new do |op|
  op.on('-c', '--config [ARG]', 'Configuration File') do |opt|
    config_file = opt
  end

  op.on('-i', '--index [ARG]', Integer, 'Worker Index') do |opt|
    index = opt
  end

  op.on('-e', '--[no-]erb', 'Treat Configuration as ERB Template') do |opt|
    erb = opt
  end
end

opts.parse!(ARGV.dup)

config_file ||= ::File.expand_path('../config/default.yml', __FILE__)
config = nil

task :default do
  begin
    config = YAML.load_file(config_file)
    config["root_dir"] = File.join(File.dirname(__FILE__))
  rescue => exception
    puts "Can't load config file: #{ exception }"
    exit 1
  end

  puts "Config file: #{config_file}"
  Bluemix::BM::App.new(config)


  resque_logging = config.fetch('resque', {}).fetch('logging', {})
  resque_log_device = Logger::LogDevice.new(resque_logging.fetch('file', STDOUT))
  resque_logger_level = resque_logging.fetch('level', 'info').upcase
  Resque.logger = Logger.new(resque_log_device)
  Resque.logger.level = Logger.const_get(resque_logger_level)
end