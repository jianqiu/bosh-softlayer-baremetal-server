require 'rubygems'
require 'softlayer_api'
require 'pp'
  
        guest_service = SoftLayer::Service.new("SoftLayer_Hardware_Server",
                                               :username => "mayunfd@cn.ibm.com", # enter your username here
                                               :api_key => "a7e9db9066024472414548ea543bcc756d67a519caa144ecb9635597b285cd82",
                                               :endpoint_url => SoftLayer::API_PRIVATE_ENDPOINT)   # enter your api key here
  SoftLayer::Client.default_client = SoftLayer::Client.new(
     :username => "mayunfd@cn.ibm.com",              # enter your username here
     :api_key => "a7e9db9066024472414548ea543bcc756d67a519caa144ecb9635597b285cd82"  # enter your api key here
  )

        # debugger # -- upen
        server = SoftLayer::BareMetalServer.server_with_id( 189646 )    #guest_service.object_with_id(115440).getObject()
    puts server["datacenter"]
exit 

  # We can set the default client to be our client and that way 
  # we can avoid supplying it later
  SoftLayer::Client.default_client = SoftLayer::Client.new(
     :username => "mayunfd@cn.ibm.com",              # enter your username here
     :api_key => "a7e9db9066024472414548ea543bcc756d67a519caa144ecb9635597b285cd82"  # enter your api key here
  )


#server = SoftLayer::BareMetalServer.server_with_id( 189646 )
server = SoftLayer::BareMetalServer.find_servers( :tags=>["bluemix.bm.new"] ) #, :hostname=> "jimmy*" ) #, :domain=> "softlayer.com" )
puts server.size
server.each{ |s|
#  puts s.softlayer_properties 
server = s.softlayer_properties
private_net = server["networkComponents"].select{|net| net["name"] == "eth" && net["port"] == 0}[0]
public_net = server["networkComponents"].select{|net| net["name"] == "eth" && net["port"] == 1}[0]
result = {
  "name" => server["hostname"],
  "root_password" => server["operatingSystem"]["passwords"][0]["password"],
  "private_ip" => private_net["primaryIpAddress"],
  "private_netmask" => private_net["primarySubnet"]["netmask"] ,
  "private_gateway" => private_net["primarySubnet"]["gateway"] ,
  "public_ip" => public_net["primaryIpAddress"],
  "public_netmask" => public_net["primarySubnet"]["netmask"] ,
  "public_gateway" => public_net["primarySubnet"]["gateway"] ,
}

puts result 
}
