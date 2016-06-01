require 'rubygems'
require 'softlayer_api'
require 'pp'

begin
  client = SoftLayer::Client.new(
     :username => "mayunfd@cn.ibm.com",              # enter your username here
     :api_key => "a7e9db9066024472414548ea543bcc756d67a519caa144ecb9635597b285cd82"  # enter your api key here
  )
  packages = SoftLayer::ProductPackage.bare_metal_server_packages(client)

  quad_intel_package = SoftLayer::ProductPackage.package_with_id(146, client)

  required_categories = quad_intel_package.configuration.select { |category| category.required? }

  os_category = quad_intel_package.category('os')
  config_options = os_category.configuration_options
  os_config_option = config_options.find { |option| option.description =~ /No Operating System/ }

  config_options = {}
  required_categories.each { |required_category| config_options[required_category.categoryCode] = required_category.default_option }

  config_options['os'] = os_config_option

  config_options.merge! ({
    'server' => 29506, # price id of Quad Processor Quad Core Intel 7420 - 2.13GHz (Dunnington) - 4 x 6MB / 8MB cache
    'port_speed' => 40642, # 1 Gbps Public & Private Network Uplinks
  })

  server_order = SoftLayer::BareMetalServerOrder_Package.new(quad_intel_package, client)
  server_order.datacenter = 'dal05'
  server_order.hostname = 'jimmy-test2'
  server_order.domain = 'softlayer.com'
  server_order.configuration_options = config_options

  begin
    private_vlan_id = 279502
    public_vlan_id = 279501
    server_order.verify() { |order|
      hardware = order["hardware"][0]
      hardware["hardDrives"] = [{
        "id" => 29372 
      }] 
      hardware["hourlyBillingFlag"] = true
      hardware["tagReferences"] = [{
        "tag" => { "name" => "bluemix.bm.new" }
      }]
      hardware["primaryBackendNetworkComponent"] = {
             "networkVlan"=> {              
                 "id"=> private_vlan_id         
                 }     
               }

      hardware["primaryNetworkComponent"] = {
	   "networkVlan"=> {
	     "id"=> public_vlan_id
	   }
	 }

      puts order
      order
    }

    puts "The Order appears to be OK"
=begin
    server_order.place_order!(){ |order|
      hardware = order["hardware"][0]
      hardware["hardDrives"] = [{
        "id" => 29372
      }]
      hardware["hourlyBillingFlag"] = true
      hardware["tagReferences"] = [{
        "tag" => { "name" => "bluemix.bm.new" }
      }]
      hardware["primaryBackendNetworkComponent"] = {
             "networkVlan"=> {
                 "id"=> private_vlan_id
                 }
               }

      hardware["primaryNetworkComponent"] = {
           "networkVlan"=> {
             "id"=> public_vlan_id
           }
         }

      puts order
      order
    }
=end
    puts "The Order is done!"
  rescue Exception => e
    puts "Order didn't verify :-( #{e}"
  end

rescue Exception => exception
  $stderr.puts "An exception occurred while trying to complete the SoftLayer API calls #{exception}"
end
