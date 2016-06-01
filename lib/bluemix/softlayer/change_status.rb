require "fog/softlayer"


@arguments = {
   :softlayer_api_url => "https://api.service.softlayer.com/xmlrpc/v3/",
#   :softlayer_api_url => "https://api.softlayer.com/xmlrpc/v3/",
#   :provider => :softlayer,
   :softlayer_username => "mayunfd@cn.ibm.com",
   :softlayer_api_key => "a7e9db9066024472414548ea543bcc756d67a519caa144ecb9635597b285cd82"
}


@service = Fog::Compute.new(@arguments)


servers = [ 291974,311816 ]
servers = [ 780189 ]

servers.each { |server_id | 

  server = @service.servers.get(server_id)
#  puts server.to_yaml
  puts server.name
  puts server.tags
#  tags = server.tags  
#  tags << "bluemix.fabrictest"
#  server.add_tags( tags )
#  server.delete_tags( ['bluemix.bm.new', 'bluemix.bm.using', 'bluemix.bm.loading', 'bluemix.bm.failed', 'bluemix.bm.deleted'] )
#  server.delete_tags( ['bm.state.new'] )
#  server.add_tags( ['bm.fabrictest'] )
#  server.add_tags( ['bm.monitise', 'bm.state.new', 'bm.p.monitise-dea'] )
#  server.add_tags( ['bm.monitise', 'bm.state.ordering', 'bm.p.monitise-dea'] )
#  server.add_tags( ['bluemix.bm.using'] )
#  server.delete_tags( ['bluemix.bm.new'] )
}


