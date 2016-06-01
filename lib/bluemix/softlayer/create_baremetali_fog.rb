require "fog/softlayer"


@arguments = {
#   :softlayer_api_url => "https://api.service.softlayer.com/xmlrpc/v3/",
#   :softlayer_api_url => "https://api.softlayer.com/xmlrpc/v3/",
   :provider => :softlayer,
   :softlayer_username => "mayunfd1%40cn.ibm.com",
   :softlayer_api_key => "cfe391d2ecafbd863564aef50c0253dd8af8a897fb78f77ec83759dc606bbe85"
}


@service = Fog::Compute.new(@arguments)

server = @service.servers.get(180368)

puts server.name
puts server.tags
exit 0
server.delete_tags( ['bluemix.bm.using'] )
server.delete_tags( ['bluemix.bm.loading'] )
server.add_tags( ['bluemix.bm.new'] )
exit 0


puts "New:"
@service.servers.tagged_with(['bluemix.bm.new']).each { |server|
  puts server.name

#  server.delete_tags( ['bluemix.bm.new'] )
#  server.add_tags( ['bluemix.bm.using'] )
}

puts "Using:"
@service.servers.tagged_with(['bluemix.bm.using']).each { |server|
  puts server.name
  server.delete_tags( ['bluemix.bm.using'] )
  server.add_tags( ['bluemix.bm.new'] )
}

puts "Loading:"
@service.servers.tagged_with(['bluemix.bm.loading']).each { |server|
  puts server.name
  server.delete_tags( ['bluemix.bm.loading'] )
  server.add_tags( ['bluemix.bm.new'] )
}
return

puts server.all_associations_and_attributes
result = {
  "name" => server.name,
  "private_ip" => server.private_network_components["primary_ip_address"],
  "private_netmask" => server.private_network_components[""],
  "private_gateway" => server.private_network_components[""],
  "private_netmask" => server.public_network_components
}

#puts result

=begin
opts = {
              :name                    => 'Medium Instance',
              :cpu                     => 4,
              :disk                    => [{'capacity' => 500 }],
              :ram                     => 4,
    :ephemeral_storage => true,
    :domain => "softlayer.com",
    :name => "jimmy-test7",
    :os_code => "UBUNTU_LATEST",
    :datacenter => "dal05",
    :bare_metal => true,
    :vlan => 279501,
    :private_vlan => 279502,
    :tagReferences => ["bluemix.bm.new"]
 }


new_staging_server = @service.servers.create(opts)
puts new_staging_server
puts new_staging_server.all_associations_and_attributes
puts new_staging_server.methods
puts new_staging_server.id

#new_staging_server.add_tags( ["bluemix.bm.new"] )
=end

=begin
staging_server.delete_tags( ["bluemix.bm.new"] )
staging_server.add_tags( ["bluemix.bm.used"] )


puts staging_server.all_associations_and_attributes
puts staging_server.ssh_password
puts staging_server.ssh_ip_address
puts staging_server.private_ip_address
=end
