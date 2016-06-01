require 'rubygems'
require 'softlayer_api'
require 'pp'
require 'yaml'
#$DEBUG=true
begin
  client = SoftLayer::Client.new(
     :username => "mayunfd1@cn.ibm.com",              # enter your username here
     :api_key => "cfe391d2ecafbd863564aef50c0253dd8af8a897fb78f77ec83759dc606bbe85"  # enter your api key here
  )
            server = SoftLayer::BareMetalServer.server_with_id( 176561, :client => client )
puts   server.getActiveTransaction() 

exit
            tags = server["tagReferences"].map{ |tagr| tagr["tag"]["name"] }
            tags.delete_if{ |tag| tag[0,9] == "bm.state." }
            tags  << "bm.state.new" 
           puts "jimmy1 #{tags.join(",")}"

exit
  server = SoftLayer::BareMetalServer.find_servers( :tags => "bm.fabrictest,bm.state.new,bm.p.fabrictest-core", :client => client )

  puts server.to_yaml

#  server.service.setTags( "bm.fabrictest,bm.state.new,bm.p.fabrictest-core" )
 exit
#  prod = SoftLayer::ProductPackage.package_with_id(200, client)
#  puts prod.to_yaml
#  prod = SoftLayer::Service.new("SoftLayer_Product_Package", :client=>client)
#  puts prod.service.getActivePresets

  servers = SoftLayer::BareMetalServer.find_servers( :tags => [ "bm.fabrictest" ], :client => client )
  puts      servers.map { |s|
          tags = s["tagReferences"].map{ |tagr| tagr["tag"]["name"] }
          {
            "id" => s["id"],
            "name" => s["hostname"],
            "private_ip_address" => s["primaryBackendIpAddress"],
            "public_ip_address" => s["primaryIpAddress"],
            "tags" => tags,
            "hardware_status" => s["hardwareStatus"]["status"],
            "memory" => s["memoryCapacity"],
            "cpu" => s["processorPhysicalCoreAmount"],
            "provision_date" => s["provisionDate"]
          }
        }.to_yaml

#  puts servers.to_yaml

  exit


  puts "Bare Metal Server Packages:"
  packages = SoftLayer::ProductPackage.bare_metal_server_packages(client)

  quad_intel_package = SoftLayer::ProductPackage.package_with_id(200, client)
  required_categories = quad_intel_package.configuration.select { |category| category.required? }

  config_options = {}
  required_categories.each { |required_category| config_options[required_category.categoryCode] = required_category.default_option }
  config_options.delete_if { |opt| opt["id"] == 0 }

  # And we can customize the default config by providing selections for any config categories
  # we are interested in
  config_options.merge! ({
    'server' => 37332, # price id of Quad Processor Quad Core Intel 7420 - 2.13GHz (Dunnington) - 4 x 6MB / 8MB cache
    'port_speed' => 24713, # 1 Gbps Public & Private Network Uplinks
    'ram' => 37344,
    'bandwidth' => 34183,
#    'disk0' =>  27537,
    'os' => 37652
  })

  # With all the config options in place we can now construct the product order.
  server_order = SoftLayer::BareMetalServerOrder_Package.new(quad_intel_package, client)
  server_order.datacenter = 'wdc01'
  server_order.hostname = 'jimmy-test1'
  server_order.domain = 'bluemix.net'
  server_order.configuration_options = config_options
  private_vlan_id =  621594
  public_vlan_id = 621592

  # The order should be complete... call verify_order to make sure it's OK.
  # you'll either get back a filled-out order, or you will get an
  # exception.  If you wanted to place the order, you would call 'place_order!' instead.
  begin
    server_order.verify(){ |order|
#    server_order.place_order!(){ |order|
      order["useHourlyPricing"] = true
      order["presetId"] = 64
      hardware = order["hardware"][0]
#      hardware["hardDrives"] = [{
#        "id" => 29372
#      }]

      hardware["tagReferences"] = [{
        "tag" => { "name" => "bluemix.bm.new" }
      }]
      hardware["primaryBackendNetworkComponent"] = {
             "networkVlan"=> {
#                 "id"=> private_vlan_id
                 }
               }

      hardware["primaryNetworkComponent"] = {
           "networkVlan"=> {
#             "id"=> public_vlan_id
           }
         }
      order["prices"].delete_if { |opt| opt["id"] == 0 }   
      puts order
      order
    }
    puts "The Order appears to be OK"
  rescue Exception => e
    puts "Order didn't verify :-( #{e}"
  end
#  puts quad_intel_package.configuration.to_yaml

  exit

#  puts SoftLayer::BareMetalServerOrder.create_object_options.to_yaml

  server_order = SoftLayer::BareMetalServerOrder.new(client)
  server_order.datacenter = 'wdc01'
  server_order.hostname = 'jimmy-test33'
  server_order.domain = 'bluemix.net'
  server_order.cores = 4
  server_order.memory = 8
  server_order.os_reference_code = 'UBUNTU_12_64'
  server_order.hourly = true
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
