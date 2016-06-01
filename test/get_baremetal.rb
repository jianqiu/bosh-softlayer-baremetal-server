require 'net/http'
require 'json'
require 'yaml'

server_id = ARGV[0]

      bm_server="http://75.126.175.119:8080"

      uri = URI("#{bm_server}/baremetal/#{server_id}")
      req = Net::HTTP::Get.new(uri.path)
      req['Authorization'] = 'Bearer ' + 'API_ACCESS_TOKEN'
      req['Content-type'] = 'text/yaml'

      res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        http.request(req)
      end

#      puts "Resp: #{res.body}"

      puts JSON.parse res.body


