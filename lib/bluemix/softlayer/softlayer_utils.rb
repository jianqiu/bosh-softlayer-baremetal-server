require 'rubygems'
require 'softlayer_api'
require 'pp'
require 'yaml'

begin
  client = SoftLayer::Client.new(
     :username => "mayunfd1@cn.ibm.com",              # enter your username here
     :api_key => "cfe391d2ecafbd863564aef50c0253dd8af8a897fb78f77ec83759dc606bbe85"  # enter your api key here
  )

  puts SoftLayer::BareMetalServerOrder.create_object_options(client).to_yaml
  server_order = SoftLayer::BareMetalServerOrder.new(client)
  server_order.datacenter = 'wdc01'
  server_order.hostname = 'jimmy-test55'
  server_order.domain = 'bluemix.net'
  server_order.cores = 4
  server_order.memory = 32
  server_order.os_reference_code = 'UBUNTU_12_64'
  server_order.hourly = false
  server_order.public_vlan_id = 621592 
  server_order.private_vlan_id = 621594
#  server_order.disks = [1000]
  server_order.max_port_speed = 1000

  begin
    server_order.verify() { |order|
      puts order
      order
    }
    puts "The Order appears to be OK"
#    server_order.place_order!()
    puts "The Order is done!"
  rescue Exception => e
    puts "Order didn't verify :-( #{e}"
  end

rescue Exception => exception
  $stderr.puts "An exception occurred while trying to complete the SoftLayer API calls #{exception} #{exception.backtrace}"
end
