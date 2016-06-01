require 'rubygems'
require 'softlayer_api'
require 'pp'
require 'yaml'

begin
  client = SoftLayer::Client.new(
     :username => "mayunfd1@cn.ibm.com",              # enter your username here
     :api_key => "cfe391d2ecafbd863564aef50c0253dd8af8a897fb78f77ec83759dc606bbe85"  # enter your api key here
  )

  puts "Bare Metal Server Packages:"
  packages = SoftLayer::ProductPackage.bare_metal_server_packages(client)
  packages.each { |package| puts "#{package.id}\t#{package.name}"}

  quad_intel_package = SoftLayer::ProductPackage.package_with_id(126, client)
  puts "\nRequired Categories for '#{quad_intel_package.name}':"
#  required_categories = quad_intel_package.configuration.select { |category| category.required? }
  required_categories = quad_intel_package.configuration   #.select { |category| category.required? }
  max_code_length = required_categories.inject(0) { |max_code_length, category| [category.categoryCode.length, max_code_length].max }
  printf "%#{max_code_length}s\tCategory Description\n", "Category Code"
  printf "%#{max_code_length}s\t--------------------\n", "-------------"
# puts required_categories.to_yaml  

  categoriey = required_categories.map { |category| 
#    next  unless quad_intel_package.category(category.categoryCode)
    os_category = category #quad_intel_package.category(category.categoryCode)
    config_options = os_category.configuration_options
    options = config_options.map { |option| {"id"=>option.price_id, "description"=>option.description} }
    {"code"=>category.categoryCode, "name"=>category.name , "options"=>options}
  }

  puts categoriey.to_yaml
exit

  required_categories.each { |category|
    printf "%#{max_code_length}s\t#{category.name}\n", category.categoryCode
    next  unless quad_intel_package.category(category.categoryCode)
    os_category = quad_intel_package.category(category.categoryCode)
    config_options = os_category.configuration_options
  puts "\nConfiguration options in the '#{category.name}' category:"
  config_options.each { |option| printf "%5s\t#{option.description}\n", option.price_id }
  }


  # We will need to provide values for each of the required category codes in our
  # configuration_options. Let's see what configuration options are available for
  # just one of the categories... Say 'os'
  os_category = quad_intel_package.category('os')
  config_options = os_category.configuration_options
  puts "\nConfiguration options in the 'os' category:"
  config_options.each { |option| printf "%5s\t#{option.description}\n", option.price_id }

  # For this example, we'll choose the first os option that contains the string 'CentOS 6'
  # in its description
  os_config_option = config_options.find { |option| option.description =~ /CentOS 6/ }

  config_options = {}
  required_categories.each { |required_category| config_options[required_category.categoryCode] = required_category.default_option }

  # print out descriptions of the the configuration options that were discovered
  puts "\nConfiguration with default options:"
  max_category_length = config_options.inject(0) { |max_category_length, pair| [pair[0].length, max_category_length].max }
  config_options.each { |category, config_option| printf "%#{max_category_length}s\t#{config_option ? config_option.description : 'no default'}\n", category }

  # Regardless of the default values... we know we want the os selection we discovered above:
  config_options['os'] = os_config_option

  # And we can customize the default config by providing selections for any config categories
  # we are interested in
  config_options.merge! ({
    'server' => 1417, # price id of Quad Processor Quad Core Intel 7420 - 2.13GHz (Dunnington) - 4 x 6MB / 8MB cache
    'port_speed' => 274 # 1 Gbps Public & Private Network Uplinks
  })

  # We have a configuration for the server, we also need a location for the new server.
  # The package can give us a list of locations. Let's print out that list
  puts "\nData Centers for '#{quad_intel_package.name}':"
  quad_intel_package.datacenter_options.each { |location| puts "\t#{location}"}

  # With all the config options in place we can now construct the product order.
  server_order = SoftLayer::BareMetalServerOrder_Package.new(quad_intel_package, client)
  server_order.datacenter = 'sng01'
  server_order.hostname = 'sample'
  server_order.domain = 'softlayerapi.org'
  server_order.configuration_options = config_options

  # The order should be complete... call verify_order to make sure it's OK.
  # you'll either get back a filled-out order, or you will get an
  # exception.  If you wanted to place the order, you would call 'place_order!' instead.
  begin
    server_order.verify(){ |order|
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
