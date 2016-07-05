require 'rubygems'
require 'softlayer_api'
require 'pp'
require "fog/softlayer"
#$DEBUG = true
module Bluemix::BM
  module Softlayer
    class BaremetalUtils

      def self.init
        config = Bluemix::BM::App.instance.config
        SoftLayer::Client.default_client = SoftLayer::Client.new(
          :username => config["softlayer"]["user"],   
          :api_key => config["softlayer"]["key"]
        )
      end

      def self.update_state2( server_id, state )
        self.update_state( server_id, ["bm.state.ordering", "bm.state.new", "bm.state.using", "bm.state.loading", "bm.state.failed", "bm.state.deleted"], [state] )
      end

      def self.update_state_new2loading( server_id )
        self.update_state( server_id, ["bm.state.new"], ["bm.state.loading"] )
      end

      def self.update_state_loading2using( server_id )
        self.update_state( server_id, ["bm.state.loading"], ["bm.state.using"])
      end

      def self.update_state_loading2failed( server_id )
        self.update_state( server_id, ["bm.state.loading"], ["bm.state.failed"] )
      end

      def self.update_state_using2new( server_id )
        self.update_state( server_id, ["bm.state.using"], ["bm.state.new"] )
      end

      def self.update_state( server_id, old_states, new_states )
        server = SoftLayer::BareMetalServer.server_with_id(server_id)

        tags = server["tagReferences"].map{ |tagr| tagr["tag"]["name"] }
        tags = tags - old_states + new_states

        server.service.setTags( tags.uniq.join(",") )
      end

      def self.reboot_baremetal( id, reboot_mode ) 
        begin
          server = SoftLayer::BareMetalServer.server_with_id( id )
          case reboot_mode
            when "soft"
              server.service.rebootSoft
            when "hard"
              server.service.rebootHard
            when "rescue"
              server.service.bootToRescueLayer
            else
              puts "reboot_baremetal: unknow mode #{reboot_mode}"
          end

        rescue => e
          puts "reboot_baremetal failed: #{e}"
        end
      end


      def self.get_baremetal_by_id( id )
        begin
          server = SoftLayer::BareMetalServer.server_with_id( id )
          self.to_server( server )
        rescue => e
          nil
        end
      end

      def self.get_baremetals( deployment_name )
        servers = SoftLayer::BareMetalServer.find_servers( :tags => [ "bm.#{deployment_name}" ] )
        servers.map { |s|
          tags = s["tagReferences"].map{ |tagr| tagr["tag"]["name"] }
          {
            "id" => s["id"],
            "hostname" => s["hostname"],
            "private_ip_address" => s["primaryBackendIpAddress"],
            "public_ip_address" => s["primaryIpAddress"],
            "tags" => tags,
            "hardware_status" => s["hardwareStatus"]["status"],
            "memory" => s["memoryCapacity"],
            "cpu" => s["processorPhysicalCoreAmount"],
            "provision_date" => s["provisionDate"]
          }
            
        }
     
      end

      def self.get_baremetal( spec_name ) 
          server = nil
          Common::Utils.do_synchronize {
            servers = SoftLayer::BareMetalServer.find_servers( :tags=>["bm.p.#{spec_name}"] )
            return if servers.nil? or servers.size == 0
            servers = servers.select { |server|
              tags = server["tagReferences"].map{ |tagr| tagr["tag"]["name"] }
              tags.include?( "bm.state.new" )
            }
            puts "jimmy1 #{servers.to_yaml}"
            return if servers.nil? or servers.size == 0
            server = servers[0].softlayer_properties
            self.update_state_new2loading( server["id"] )
          }
          self.to_server( server )
      end

      def self.to_server( server )
        private_net = server["networkComponents"].select{|net| net["name"] == "eth" && net["port"] == 0}[0]
        private_vlan = server["networkVlans"].select{|net| net["networkSpace"] == "PRIVATE"}[0]
        public_net = server["networkComponents"].select{|net| net["name"] == "eth" && net["port"] == 1}[0]
        {
          "id" => server["id"],
          "hostname" => server["hostname"],
          "fullyQualifiedDomainName"=> server['fullyQualifiedDomainName'],
          "root_password" => server["operatingSystem"]["passwords"][0]["password"],
          "private_ip" => private_net["primaryIpAddress"],
          "private_subnet" => private_net["primarySubnet"]["networkIdentifier"],
          "private_netmask" => private_net["primarySubnet"]["netmask"] ,
          "private_gateway" => private_net["primarySubnet"]["gateway"] ,
          "private_vlan_id" => private_vlan["id"],
          "public_ip" => public_net["primaryIpAddress"],
          "public_subnet" => public_net["primarySubnet"]["networkIdentifier"],
          "public_netmask" => public_net["primarySubnet"]["netmask"] ,
          "public_gateway" => public_net["primarySubnet"]["gateway"] ,
          "networkComponents" => server["networkComponents"]
        }
      end     

      def self.get_package_options( pkg_id )
        package = SoftLayer::ProductPackage.package_with_id(pkg_id)

        categories = package.configuration.map { |category|
          config_options = category.configuration_options
          options = config_options.map { |option| {"id"=>option.price_id, "description"=>option.description} }
          {"code"=>category.categoryCode, "name"=>category.name , "options"=>options, "required"  => category.required?}
        }
        datacenters = package.datacenter_options.map { |e| "#{e["name"]} - #{e["longName"]}" }
        {"categories"=>categories, "datacenters"=>datacenters}
      end

      def self.get_packages()
        packages = SoftLayer::ProductPackage.bare_metal_server_packages()
        pkgs = packages.map { |package| {"id"=>package.id, "name"=>package.name} }
        {"packages"=>pkgs}
      end
 
      def self.wait_baremetals_ready( deployment_name, baremetals )
        Bluemix::BM::App.instance.config["event_loger"].event_info( "Begin to wait for the baremetals ready: #{baremetals.join(", ")}!!" )
        bms_tags = baremetals.dup
        60.times {
          break if bms_tags.empty?
          bms_tags.delete_if{ |bm|
            servers = SoftLayer::BareMetalServer.find_servers(:hostname => bm[0])
            if !servers.nil? && servers.size == 1
              server = servers[0]
              server.service.setTags( "bm.#{deployment_name},bm.state.ordering,bm.p.#{bm[1]}" )
              Bluemix::BM::App.instance.config["event_loger"].event_info( "Set tags for #{bm[0]} (ID: #{server["id"]}) in resource pool #{bm[1]}" )
              true
            else
              false
            end
          }
          sleep 60
        }

        # the most waiting time is 20 hours
        bms = baremetals.dup
        240.times {
          break if bms.empty?
          bms.delete_if{ |bm|
            servers = SoftLayer::BareMetalServer.find_servers(:hostname => bm[0])
            if !servers.nil? && servers.size == 1 && !servers[0]["provisionDate"].nil? && servers[0]["provisionDate"].size > 8
              server = servers[0]
              server.service.setTags( "bm.#{deployment_name},bm.state.new,bm.p.#{bm[1]}" )
              Bluemix::BM::App.instance.config["event_loger"].event_info( "#{bm[0]} (ID: #{server["id"]}) in resource pool #{bm[1]} is ready, provision data: #{server["provisionDate"]}" )
              true
            else
              false
            end
          }
          sleep 300
        }
        raise "Timeout to provision the baremetals #{bms.map{|e| "#{e[0]} in #{e[1]}" }.join(", ")}" unless bms.empty?
      end

      def self.get_missed_baremetals( bm_specs )
        specs = bm_specs["baremetal_specs"]
        deployment = bm_specs["deployment"]
        Bluemix::BM::App.instance.config["event_loger"].event_info( "Begin to check missed baremetals ..." )
        results = []
        all_servers = SoftLayer::BareMetalServer.find_servers(:tags => [ "bm.#{deployment}" ]) || []
        specs.each { | spec |
          Bluemix::BM::App.instance.config["event_loger"].event_info( "Begin to check the missed baremetals for spec #{spec["name_prefix"]}, size #{spec["size"]}" )
          existed = all_servers.count{ |server| 
            tags = server["tagReferences"].map{ |tagr| tagr["tag"]["name"] }
            tags ? tags.include?( "bm.p.#{spec["name_prefix"]}" ) : false 
          }
          spec["size"] = spec["size"] - existed
          Bluemix::BM::App.instance.config["event_loger"].event_info( "   Existed #{existed}, so will create #{spec["size"]} baremetals for spec #{spec["name_prefix"]}" )
        }
        bm_specs
      end

      def self.create_baremetals( bm_specs, place_order = true )
        specs = bm_specs["baremetal_specs"]
        Bluemix::BM::App.instance.config["event_loger"].event_info( "Begin to create baremetals ..." )
        results = []
        specs.each { | spec |
          Bluemix::BM::App.instance.config["event_loger"].event_info( "Begin to create baremetals for spec #{spec["name_prefix"]}, size #{spec["size"]}" )
          spec["size"].times{
            name = ""
            begin
              name = spec["name_prefix"] + "-" + Time.now.utc.localtime.strftime("%Y%m%d-%H%M%S-%L")
              create_baremetal_2( name, spec.dup, place_order )
              results << [name, 1, "ordered", spec["name_prefix"]]
              Bluemix::BM::App.instance.config["event_loger"].event_info( "Ordered #{name}!!" )
              sleep 1
            rescue => e
              puts "Failed to create baremetal #{name}, error: #{e}, calls #{e.backtrace}"
              Bluemix::BM::App.instance.config["event_loger"].event_error( "Failed to order #{name}, Error: #{e}" )
              results << [name, 0, "Error: #{e}", spec["name_prefix"]]
            end
          }
        }
        results
      end

      def self.create_baremetal(name, spec, place_order )
          server_spec = spec["server_spec"]
          Bluemix::BM::App.instance.config["event_loger"].event_info( "Spec: #{spec.to_json}" )
          package_id = server_spec.delete( "package" ) 
          package = SoftLayer::ProductPackage.package_with_id( package_id )
          required_categories = package.configuration.select { |category| category.required? }

          config_options = {}
          required_categories.each { |required_category| config_options[required_category.categoryCode] = required_category.default_option }

          server_order = SoftLayer::BareMetalServerOrder_Package.new(package)
          server_spec.each { |k,v|
            if server_order.respond_to?( "#{k}=" )  
              server_order.send( "#{k}=", v )
              server_spec.delete( k ) 
            end 
          }
          config_options.merge!( server_spec )
          puts "Options : #{config_options.to_json}"

          server_order.datacenter = SoftLayer::Datacenter.datacenter_named( spec["datacenter"] )
          server_order.hostname = name
          server_order.domain = 'bluemix.net'
          server_order.configuration_options = config_options


          order_proc = Proc.new { |order|
=begin
            order["useHourlyPricing"] = spec["hourly_pricing"]
            order["presetId"] = spec["preset_id"] if spec["preset_id"]
            hardware = order["hardware"][0]
            hardware["hourlyBillingFlag"] = true
            hardware["primaryBackendNetworkComponent"] = {
              "networkVlan"=> {
                "id"=> spec["private_vlan_id"]
               }
            }
            hardware["primaryNetworkComponent"] = {
              "networkVlan"=> {
                "id"=> spec["public_vlan_id"]
              }
            }
=end
            order["prices"].delete_if { |price| price["id"] == 0 }
            Bluemix::BM::App.instance.config["event_loger"].event_info( "Order with: #{order.to_json}" )
            order
          }

          if place_order
#             server_order.place_order!
            server_order.place_order!{ |order|
              order_proc.call order
            }
          else
#             server_order.verify
            server_order.verify{ |order|
              order_proc.call order
            }
          end

      end

      def self.create_baremetal_2(name, spec, place_order )
        server_spec = spec["server_spec"]
        Bluemix::BM::App.instance.config["event_loger"].event_info( "Spec: #{spec.to_json}" )

        server_order = SoftLayer::BareMetalServerOrder.new()
        server_order.cores = server_spec["cores"]
        server_order.datacenter = SoftLayer::Datacenter.datacenter_named( spec["datacenter"] )
        server_order.hostname = name
        server_order.domain = spec["domain"]
        server_order.hourly = server_spec["hourly"]
        server_order.max_port_speed = server_spec["max_port_speed"]
        server_order.memory = server_spec["memory"]
        server_order.private_vlan_id = server_spec["private_vlan_id"]
        server_order.public_vlan_id = server_spec["public_vlan_id"]
        server_order.os_reference_code = 'CENTOS_7_64'

        if place_order
          server_order.place_order!
        else
          server_order.verify
        end

      end

    end
  end

end

