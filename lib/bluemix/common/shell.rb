module Bluemix::BM
  module Common
    class Shell

      def self.run_command(command, options = {})
        puts command if options[:output_command]
        status = 0
        output = []

       IO.popen( command ) do |io|
         while line = io.gets
           output << line.chomp
         end
         io.close
         status = $?.to_i 
       end

       [ status,  output ]
      end

    end
  end
end

