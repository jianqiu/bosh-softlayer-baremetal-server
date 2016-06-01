require 'net/http'
require 'json'
require 'yaml'

task_id = ARGV[0]


resource_pool = { "name" => "core" }

uri = URI('http://75.126.175.119:8080/baremetal')
req = Net::HTTP::Put.new(uri.path)
req.body = resource_pool.to_yaml
req['Authorization'] = 'Bearer ' + 'API_ACCESS_TOKEN'
req['Content-type'] = 'text/yaml'
   
res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') do |http|
  http.request(req)
end

puts "Resp: #{res.body}"

result = JSON.parse res.body
task_id = result["task_id"]


uri = URI("http://75.126.175.119:8080/task/#{task_id}/server.info")
go = true
while go
  res = Net::HTTP.get_response(uri)
  body =  res.body
  puts "State: #{body}"
  state = JSON.parse body
  if state["state"] == "Completed"
    break
  else
    sleep 5
  end
end


