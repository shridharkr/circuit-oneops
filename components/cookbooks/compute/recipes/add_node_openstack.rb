# Copyright 2016, Walmart Stores, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fog'
require 'json'

# set fog / excon timeouts to 5min
Excon.defaults[:read_timeout] = 300
Excon.defaults[:write_timeout] = 300

#
# supports openstack-v2 auth
#

cloud_name = node[:workorder][:cloud][:ciName]
compute_service = node[:workorder][:services][:compute][cloud_name][:ciAttributes]

conn = Fog::Compute.new({
  :provider => 'OpenStack',
  :openstack_api_key => compute_service[:password],
  :openstack_username => compute_service[:username],
  :openstack_tenant => compute_service[:tenant],
  :openstack_auth_url => compute_service[:endpoint]
})


# net_id for specifying network to use via subnet attr
net_id = ''
begin
  quantum = Fog::Network.new({
    :provider => 'OpenStack',
    :openstack_api_key => compute_service[:password],
    :openstack_username => compute_service[:username],
    :openstack_tenant => compute_service[:tenant],
    :openstack_auth_url => compute_service[:endpoint]
  })
  
  quantum.networks.each do |net|
    if net.name == compute_service[:subnet]
      Chef::Log.info("net_id: "+net.id)
      net_id = net.id
      break
    end
  end
rescue Exception => e
  Chef::Log.warn("no quantum networking installed")
end

rfcCi = node["workorder"]["rfcCi"]
nsPathParts = rfcCi["nsPath"].split("/")
customer_domain = node["customer_domain"]
owner = node.workorder.payLoad.Assembly[0].ciAttributes["owner"] || "na"
node.set["max_retry_count_add"] = 30

Chef::Log.info("compute::add -- name: "+node.server_name+" domain: "+customer_domain+" provider: "+cloud_name)  
Chef::Log.debug("rfcCi attrs:"+rfcCi["ciAttributes"].inspect.gsub("\n"," "))

flavor = ""
image = ""
availability_zones = []
availability_zone = ""
manifest_ci = {}
scheduler_hints = {}
server = nil

ruby_block 'set flavor/image/availability_zone' do
  block do  
  
    
    if compute_service.has_key?("availability_zones") && !compute_service[:availability_zones].empty?
      availability_zones = JSON.parse(compute_service[:availability_zones])
    end
    
    if availability_zones.size > 0
      case node.workorder.box.ciAttributes.availability
      when "redundant"
        instance_index = node.workorder.rfcCi.ciName.split("-").last.to_i + node.workorder.box.ciId
        index = instance_index % availability_zones.size
        availability_zone = availability_zones[index]
      else
        random_index = rand(availability_zones.size)
        availability_zone = availability_zones[random_index]
      end
    end
    
    manifest_ci = node.workorder.payLoad.RealizedAs[0]
    
    if manifest_ci["ciAttributes"].has_key?("required_availability_zone") &&
      !manifest_ci["ciAttributes"]["required_availability_zone"].empty?
      
      availability_zone = manifest_ci["ciAttributes"]["required_availability_zone"]
      Chef::Log.info("using required_availability_zone: #{availability_zone}")
    end
    
    if ! rfcCi["ciAttributes"]["instance_id"].nil? && ! rfcCi["ciAttributes"]["instance_id"].empty?
      server = conn.servers.get(rfcCi["ciAttributes"]["instance_id"])      
    else
      conn.servers.all.each do |i| 
        if i.name == node.server_name && i.os_ext_sts_task_state != "deleting" && i.state != "DELETED" 
          server = i
          break
        end
      end
      puts "***RESULT:instance_id=#{server.id}" unless server.nil?
    end

    if server.nil?
      # size / flavor
      flavor = conn.flavors.get node.size_id
      Chef::Log.info("flavor: "+flavor.inspect.gsub("\n"," ").gsub("<","").gsub(">",""))
      if flavor.nil?
        Chef::Log.error("cannot find flavor: #{node.size_id}")
        exit 1
      end
        
      # image_id
      image = conn.images.get node.image_id  
      Chef::Log.info("image: "+image.inspect.gsub("\n"," ").gsub("<","").gsub(">",""))
      if image.nil?
        Chef::Log.error("cannot find image: #{node.image_id}")
        exit 1
      end
    else
      if ["BUILD","ERROR"].include?(server.state)
        msg = "vm #{server.id} is stuck in #{server.state} state"
        puts "***FAULT:FATAL=#{msg}"
        e = Exception.new("no backtrace")
        e.set_backtrace("")
        raise e  
      end        
      node.set[:existing_server] = true
    end
      
  end
end

# security groups
security_groups = []
ruby_block 'setup security groups' do
  block do

    secgroups = []
    if node[:workorder][:payLoad].has_key?("DependsOn") && 
      secgroups = node[:workorder][:payLoad][:DependsOn].select{ |ci| ci[:ciClassName] =~ /Secgroup/ }  
    end

    secgroups.each do |sg|
      if sg[:rfcAction] != "delete"
        security_groups.push(sg[:ciAttributes][:group_id])
        Chef::Log.info("Server inspect :::" + server.inspect)
        #Skip the dynamic sg update for ndc/edc due to OpenStack incompatibility
        unless (server.nil? || server.state != "ACTIVE") || ((cloud_name.include? "ndc") || (cloud_name.include? "edc"))
          # add_security_group to the existing compute instance. works for update calls as well for existing security groups
          begin
            res = conn.add_security_group(server.id, sg[:ciAttributes][:group_name])
            Chef::Log.info("add secgroup response for sg: #{sg[:ciAttributes][:group_name]}: "+res.inspect)
          rescue Excon::Errors::Error =>e
             msg=""
             case e.response[:body]
             when /\"code\": 400/
              msg = JSON.parse(e.response[:body])['badRequest']['message']
              Chef::Log.error("error response body :: #{msg}")
              puts "***FAULT:FATAL=OpenStack API error: #{msg}"
              raise Excon::Errors::BadRequest, msg
             else
              msg = e.message
              puts "***FAULT:FATAL=OpenStack API error: #{msg}"
              raise Excon::Errors::Error, msg
             end
          rescue Exception => ex
              msg = ex.message
              puts "***FAULT:FATAL= #{msg}"
              e = Exception.new("no backtrace")
              e.set_backtrace("")
              raise e  
          end  
        end  
      end  
    end
    
    # add default security group
    sg = conn.list_security_groups.body['security_groups'].select { |g| g['name'] == "default"}
    Chef::Log.info("sg: #{sg.inspect}")
    security_groups.push(sg.first["id"])
    
    Chef::Log.info("security_groups: #{security_groups.inspect}") 

  end
end


=begin 
  
  openstack vm metadata:
  owner ( assembly attr )  
  mgmt_url ( new inductor property)
  organization (org ciName)
  assembly (assembly ciName)
  environment (environment ciName)
  platform (box ciName)
  component (RealizedAs ciId)
  instance (Rfc ciId)

=end

mgmt_url = "https://"+node.mgmt_domain
if node.has_key?("mgmt_url") && !node.mgmt_url.empty?
  mgmt_url = node.mgmt_url
end

metadata = { 
  "owner" => owner,
  "mgmt_url" =>  mgmt_url,
  "organization" => node.workorder.payLoad[:Organization][0][:ciName],
  "assembly" => node.workorder.payLoad[:Assembly][0][:ciName],
  "environment" => node.workorder.payLoad[:Environment][0][:ciName],
  "platform" => node.workorder.box.ciName,
  "component" => node.workorder.payLoad[:RealizedAs][0][:ciId].to_s,
  "instance" => node.workorder.rfcCi.ciId.to_s
}

ruby_block 'create server' do
  block do

    if server.nil?
      Chef::Log.info("server not found - creating")
      
      # openstack cant have .'s in key_pair name
      node.set["kp_name"] = node.kp_name.gsub(".","-")
      
      begin        
        
        # network / quantum support   
        if !net_id.empty?
       
          Chef::Log.info("metadata: "+metadata.inspect+ " key_name: #{node.kp_name}")  
       
          server_request = {
            :name => node.server_name,
            :image_ref => image.id,
            :flavor_ref => flavor.id,
            :key_name => node.kp_name,
            :security_groups => security_groups,
            :metadata => metadata,
            :nics => [ { "net_id" => net_id } ]
          }
          
          if !availability_zone.empty?
            server_request[:availability_zone] = availability_zone
            puts "***RESULT:availability_zone=#{availability_zone}"
          end
          
          if scheduler_hints.keys.size > 0
            server_request[:scheduler_hints] = scheduler_hints
          end
    
        else
          # older versions of openstack do not allow nics or security_groups
          server_request = {
            :name => node.server_name,
            :image_ref => image.id,
            :flavor_ref => flavor.id,
            :key_name => node.kp_name
          }
        end
        
        start_time = Time.now.to_i
        
        server = conn.servers.create server_request
     
        end_time = Time.now.to_i
        
        duration = end_time - start_time
        
        Chef::Log.info("server create returned in: #{duration}s")
      
        rescue Exception =>e
          message = ""
          case e.message
          when /Request Entity Too Large/,/Quota exceeded/
            limits = conn.get_limits.body["limits"]
            Chef::Log.info("limits: "+limits["absolute"].inspect)
            Chef::Log.error("openstack quota exceeded for tenant: #{compute_service[:tenant]} user: #{compute_service[:tenant]} - see limits above.")
            message = "openstack quota exceeded"
          else
            message = e.message
          end
          
          case e.response[:body]
           when /\"code\": 400/
            message = JSON.parse(e.response[:body])['badRequest']['message']
          end
          
          if message =~ /Invalid imageRef provided/
               Chef::Log.error(" #{node[:ostype]} OS type does not exist. Select the different OS type and retry the deployment")
               message = "Select the different OS type in compute component and retry the deployment"
          end
          
          if message =~ /availability zone/ && server_request.has_key?(:availability_zone)
            Chef::Log.info("availability zone: #{server_request[:availability_zone]}")
          end
          
          puts "***FAULT:FATAL="+message
          e = Exception.new("no backtrace")
          e.set_backtrace("")
          raise e
          
        end
    
      # give openstack a min
      sleep 60
    
      # wait for server to be ready checking every 30 sec
      server.wait_for( Fog.timeout, 20 ) { server.ready? }
      
      end_time = Time.now.to_i  
      duration = end_time - start_time
      
      Chef::Log.info("server ready in: #{duration}s")
      
    end
  
    Chef::Log.info("server: "+server.inspect.gsub("\n"," ").gsub("<","").gsub(">",""))
    puts "***RESULT:instance_id="+server.id
    hypervisor = server.os_ext_srv_attr_hypervisor_hostname || ""
    puts "***RESULT:hypervisor="+hypervisor
    puts "***RESULT:instance_state="+server.state
    task_state = server.os_ext_sts_task_state || ""
    puts "***RESULT:task_state="+task_state
    vm_state = server.os_ext_sts_vm_state || ""
    puts "***RESULT:vm_state="+server.os_ext_sts_vm_state
    puts "***RESULT:metadata="+JSON.dump(metadata)

  end
end

private_ip = ''
public_ip = ''

ruby_block 'set node network params' do
  block do
    if server.addresses.has_key? "public"
      public_ip = server.addresses["public"][0]["addr"]
      node.set[:ip] = public_ip
      puts "***RESULT:public_ip="+public_ip 
      if ! server.addresses.has_key? "private" 
        puts "***RESULT:dns_record="+public_ip 
        # in some openstack installs only public_ip is set 
        # lets set private_ip to this addr too for other cookbooks which use private_ip
        private_ip = public_ip   
        puts "***RESULT:private_ip="+private_ip   
      end
    end
    
    # use private ip if both are set
    if server.addresses.has_key? "private" 
      private_ip = server.addresses["private"][0]["addr"]
      node.set[:ip] = private_ip
      puts "***RESULT:private_ip="+private_ip
      puts "***RESULT:dns_record="+private_ip
    end
    
    # specific network
    if !compute_service[:subnet].empty?
       
      network_name = compute_service[:subnet]
      if server.addresses.has_key?(network_name)
        
        addrs = server.addresses[network_name]
        addrs_map = {}
        # some time openstack returns 2 of same addr
        addrs.each do |addr|
          next if ( addr.has_key? "OS-EXT-IPS:type" && addr["OS-EXT-IPS:type"] != "fixed" )
          ip = addr['addr']
          if addrs_map.has_key? ip
            puts "***FAULT:FATAL=The same ip #{ip} returned multiple times"
            e = Exception.new("no backtrace")
            e.set_backtrace("")
            raise e
          end
          addrs_map[ip] = 1
        end
        private_ip = addrs.first["addr"]
        node.set[:ip] = private_ip
      end
    end
    
    if private_ip.empty?
      server.addresses.each_value do |addr_list|
        addr_list.each do |addr|
          puts "addr: #{addr.inspect}"
          if addr["OS-EXT-IPS:type"] == "fixed"
            private_ip = addr["addr"]
            node.set[:ip] = private_ip
          end          
        end
      end
    end
    
    if((public_ip.nil? || public_ip.empty?) && 
       rfcCi["rfcAction"] != "add" && rfcCi["rfcAction"] != "replace")
      
      public_ip = node.workorder.rfcCi.ciAttributes.public_ip
      node.set[:ip] = public_ip
      Chef::Log.info("node ip: " + node.ip)
      Chef::Log.info("Fetching ip from workorder rfc for compute update")
    end


    if node.workorder.rfcCi.ciAttributes.require_public_ip == 'true' && public_ip.empty?
      
      if compute_service[:public_network_type] == "floatingip"
        
        server.addresses.each_value do |addr_list|
          addr_list.each do |addr|
            puts "addr: #{addr.inspect}"
   
            if addr["OS-EXT-IPS:type"] == "floating"
              public_ip = addr["addr"]
              node.set["ip"] = public_ip
            end
          end
        end
        
        if public_ip.empty?
          floating_ip = conn.addresses.create
          floating_ip.server = server
          public_ip = floating_ip.ip
        end
            
      end      
      
    end
   
    
    puts "***RESULT:public_ip="+public_ip
    dns_record = public_ip
    if dns_record.empty? && !private_ip.empty?
      dns_record = private_ip
    end
    puts "***RESULT:dns_record="+dns_record
    # lets set private_ip to this addr too for other cookbooks which use private_ip
    puts "***RESULT:private_ip="+private_ip       
    puts "***RESULT:host_id=#{server.host_id}"
    
    if node.ip_attribute == "private_ip"
      node.set[:ip] = private_ip
      Chef::Log.info("setting node.ip: #{private_ip}")
    else
      node.set[:ip] = public_ip      
      Chef::Log.info("setting node.ip: #{public_ip}")
    end
    
    if server.image.has_key? "id"
	    server_image_id = server.image["id"]
	    server_image = conn.images.get server_image_id
	    if ! server_image.nil?
        puts "***RESULT:server_image_id=" + server_image_id
		    puts "***RESULT:server_image_name=" + server_image.name
	    end 
    end
  end
end

ruby_block 'catch errors/faults' do
  block do
    # catch faults
    if !server.fault.nil? && !server.fault.empty?
      Chef::Log.error("server.fault: "+server.fault.inspect)
      if server.fault.inspect =~ /NoValidHost/
          puts "***FAULT:FATAL=NoValidHost - #{cloud_name} openstack doesn't have resources to create your vm."
      end
      e = Exception.new("no backtrace")
      e.set_backtrace("")
      raise e
    end
    
    # catch other, e.g. stuck in BUILD state
    if !node.has_key?("ip") || node.ip.nil?
      msg = "server.state: "+ server.state + " and no ip for vm: #{server.id}"
      Chef::Log.error(msg)
      puts "***FAULT:FATAL=#{msg}"
      e = Exception.new("no backtrace")
      e.set_backtrace("")
      raise e
    end
  
  end
end      
    
include_recipe "compute::ssh_port_wait"
    
ruby_block 'handle ssh port closed' do
  block do
        
    if node[:ssh_port_closed]
      Chef::Log.error("ssh port closed after 5min, dumping console log")
      begin
        console_log = server.console.body
      
        console_log["output"].split("\n").each do |row|
          case row
          when /IP information for eth0... failed|Could not retrieve public key from instance metadata/
            puts "***FAULT:KNOWN=#{row}"
          else
            puts "***FAULT:FATAL=SSH port not open on VM"  
          end      
          Chef::Log.info("console-log:" +row)
        end
      rescue Exception => e        
        Chef::Log.error("could not dump console-log. exception: #{e.inspect}")
      end
        
      Chef::Log.error("ssh port closed after 5min - fail")
      e = Exception.new("no backtrace")
      e.set_backtrace("")
      raise e 
    end
    
  end
end
