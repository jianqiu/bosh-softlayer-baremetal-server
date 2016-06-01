module Bluemix::BM
  module Common
    class TaskUtils
      TASK_INFO_FILE="task"


      def self.init_logger( taskid )
        Bluemix::BM::App.instance.config["event_loger"] = Bluemix::BM::Common::TaskLogger.new( taskid )
      end

      def self.close_logger( taskid )
        Bluemix::BM::App.instance.config["event_loger"].close
      end

      def self.get_new_taskid()
        config = Bluemix::BM::App.instance.config
        data_file = "#{config['store_dir']}/data.yml"
        data = File.exist?( data_file) ? YAML.load_file( data_file ) : {}
        data["task_id"] = 0 unless data["task_id"]
        data["task_id"] = data["task_id"] + 1
        
        File.open( data_file, "w+" ) { |f|
          f.write( data.to_yaml)
        }
        data["task_id"]
      end

      def self.get_task_txt_resource( task_id, res_name )
        self.task_exists( task_id )
        @config = Bluemix::BM::App.instance.config
        res_file = File.join("#{@config['store_dir']}/tasks/#{task_id}", res_name)
        if File.exist?( res_file ) 
          File.readlines( res_file )
        else
          ["No #{res_name} found!"]
        end
      end

      def self.get_latest_tasks( latest )
        config = Bluemix::BM::App.instance.config

        latest_tasks_dir = Dir.glob("#{config['store_dir']}/tasks/*").sort_by{ |f| File.ctime(f) }.reverse!.first( latest )

        latest_tasks = []

        latest_tasks_dir.each { | task_dir | 
          info_file = "#{task_dir}/#{TASK_INFO_FILE}"
          next  unless File.exist?( info_file)
          latest_tasks << YAML.load_file( info_file )
        }

        latest_tasks 

      end

      def self.create_task( description )
        config = Bluemix::BM::App.instance.config
        taskid = self.get_new_taskid()
        FileUtils.mkdir "#{config['store_dir']}/tasks/#{taskid}"
        self.update_task_info(taskid, {
          "id" => taskid,
          "description" => description,
          "start_time" => Time.now,
          "status" => "running" 
        })
        taskid
      end

      def self.get_task_status( task_id )
        self.task_exists( task_id )
        config = Bluemix::BM::App.instance.config
        info_file = "#{config['store_dir']}/tasks/#{task_id}/#{TASK_INFO_FILE}"
        info = YAML.load_file( info_file )
        { "status" => info["status"] }
      end

      def self.get_task_resource( task_id, file_name )
        self.task_exists( task_id )
        config = Bluemix::BM::App.instance.config
        info_file = "#{config['store_dir']}/tasks/#{task_id}/#{file_name}"
        File.exist?( info_file) ? YAML.load_file( info_file ) : {}
      end

      def self.update_task_info( task_id, info )
        self.task_exists( task_id )
        config = Bluemix::BM::App.instance.config
        info_file = "#{config['store_dir']}/tasks/#{task_id}/#{TASK_INFO_FILE}"
        task_info = File.exist?( info_file) ? YAML.load_file( info_file ) : {}
        task_info.merge!( info )
        File.open( info_file, "w+" ) { |f|
          f.write( task_info.to_yaml)
        }
      end

      def self.update_task_status( task_id, status )
        status = {
          "status" => status
        }
        self.update_task_info( task_id, status )
      end

      def self.enqueue(queue, job_class, description, params)
        task_id = self.create_task( description )
        Resque.enqueue_to(queue, job_class, task_id, *params)

        task_id
      end

      def self.task_exists( task_id )
        config = Bluemix::BM::App.instance.config
        task_dir = "#{config['store_dir']}/tasks/#{task_id}/"
        raise "Task #{task_id} is not existed" unless Dir.exist? task_dir
      end

      def json_decode(payload)
        Yajl::Parser.parse(payload)
      end

    end
  end
end

