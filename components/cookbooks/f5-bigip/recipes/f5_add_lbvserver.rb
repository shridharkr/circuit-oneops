# use previous dns_record attr for ip of cloud-level lb only if cloud vips were previously created
ip = nil
if node.workorder.rfcCi.ciAttributes.has_key?("dns_record") &&
   node.workorder.rfcCi.ciBaseAttributes.has_key?("create_cloud_level_vips") &&
   node.workorder.rfcCi.ciBaseAttributes.create_cloud_level_vips == "true"
  ip = node.workorder.rfcCi.ciAttributes.dns_record
end

cloud_level_ip = nil
dc_level_ip = nil 

# uploads certkey
include_recipe "f5-bigip::f5_add_cert_key"
require_relative "../libraries/resource_ltm_virtual_server"
require_relative "../libraries/resource_config_sync"
#require_relative "../resources/getsetlbip"

node.loadbalancers.each do |lb|
	profiles_list = [{ 'profile_context' =>  'PROFILE_CONTEXT_TYPE_ALL', 'profile_name'	=> "/Common/tcp"}]
	profiles_list = [{ 'profile_context' =>  'PROFILE_CONTEXT_TYPE_ALL', 'profile_name'	=> "/Common/http"}] if ["SSL","HTTPS","HTTP"].include?(lb[:vprotocol].upcase)
	profiles_list.push({'profile_context' => 'PROFILE_CONTEXT_TYPE_CLIENT', 'profile_name'	=>	"#{node.cert_name}" }) if lb[:vprotocol] == ("SSL" || "HTTPS")
	n = f5_bigip_getsetlbip "#{lb['name']}" do
		ipv46 "#{ip}"
		f5_ip "#{node.f5_host}"
		action :create
	end
	n.run_action(:create)
	if node.workorder.rfcCi.ciAttributes.stickiness == "true"
		if ["SSL","HTTPS","HTTP"].include?(lb[:vprotocol].upcase)
			f5_ltm_virtual_server "#{lb[:name]}" do
				vs_name lb[:name]
				f5 node.f5_host
				default_pool "#{lb[:sg_name]}"
				destination_address	node.ns_lbvserver_ip
				connection_limit 12
				destination_port lb[:vport].to_i
				profiles profiles_list
				default_persistence_profile	'/Common/cookie'
				fallback_persistence_profile '/Common/source_addr'
				enabled true
				action :create
				notifies :run, "f5_config_sync[#{node.f5_host}]", :immediately
			end
		else
			f5_ltm_virtual_server "#{lb[:name]}" do
				vs_name lb[:name]
				f5 node.f5_host
				default_pool "#{lb[:sg_name]}"
				destination_address	node.ns_lbvserver_ip
				connection_limit 12
				destination_port lb[:vport].to_i
				profiles profiles_list
				default_persistence_profile '/Common/source_addr'
				enabled true
				action :create
				notifies :run, "f5_config_sync[#{node.f5_host}]", :immediately
			end
		end
	else
		if ["SSL","HTTPS","HTTP"].include?(lb[:vprotocol].upcase)
			f5_ltm_virtual_server "#{lb[:name]}" do
				vs_name lb[:name]
				f5 node.f5_host
				default_pool "#{lb[:sg_name]}"
				destination_address	node.ns_lbvserver_ip
				connection_limit 12
				destination_port lb[:vport].to_i
				profiles profiles_list
				enabled true
				action :create
				notifies :run, "f5_config_sync[#{node.f5_host}]", :immediately
			end
		else
			f5_ltm_virtual_server "#{lb[:name]}" do
				vs_name lb[:name]
				f5 node.f5_host
				default_pool "#{lb[:sg_name]}"
				destination_address	node.ns_lbvserver_ip
				connection_limit 12
				destination_port lb[:vport].to_i
				profiles profiles_list
				enabled true
				action :create
				notifies :run, "f5_config_sync[#{node.f5_host}]", :immediately
			end
		end		
			
	end
	cloud_level_ip = node["ns_lbvserver_ip"]	
end

# reset so cloud and dc vips have different ip
node.set["ns_lbvserver_ip"] = ""
ip = nil
if node.workorder.rfcCi.ciAttributes.has_key?("dns_record") &&
   !node.workorder.rfcCi.ciBaseAttributes.has_key?("create_cloud_level_vips") &&
   node.workorder.rfcCi.ciAttributes.create_cloud_level_vips == "false" &&
   node.workorder.rfcCi.rfcAction != "replace"
  
   ip = node.workorder.rfcCi.ciAttributes.dns_record
end

node.dcloadbalancers.each do |lb|
	profiles_list = [{ 'profile_context' =>  'PROFILE_CONTEXT_TYPE_ALL', 'profile_name'	=> "/Common/tcp"}]
	profiles_list = [{ 'profile_context' =>  'PROFILE_CONTEXT_TYPE_ALL', 'profile_name'	=> "/Common/http"}] if ["SSL","HTTPS","HTTP"].include?(lb[:vprotocol].upcase)
	profiles_list.push({'profile_context' => 'PROFILE_CONTEXT_TYPE_CLIENT', 'profile_name'	=>	"#{node.certname}" }) if lb[:vprotocol] == ("SSL" || "HTTPS")

	n = f5_bigip_getsetlbip "#{lb['name']}" do
		ipv46 "#{ip}"
		f5_ip "#{node.f5_host}"
		action :create
	end
	n.run_action(:create)
	if node.workorder.rfcCi.ciAttributes.stickiness == "true"
		if ["SSL","HTTPS","HTTP"].include?(lb[:vprotocol].upcase)
			f5_ltm_virtual_server "#{lb[:name]}" do
				vs_name lb[:name]
				f5 node.f5_host
				default_pool "#{lb[:sg_name]}"
				destination_address	"1.1.1.4"
				connection_limit 12
				destination_port lb[:vport].to_i
				profiles profiles_list
				default_persistence_profile	'/Common/cookie'
				fallback_persistence_profile '/Common/source_addr'
				enabled true
				action :create
			end
		else
			f5_ltm_virtual_server "#{lb[:name]}" do
				vs_name lb[:name]
				f5 node.f5_host
				default_pool "#{lb[:sg_name]}"
				destination_address	"1.1.1.4"
				connection_limit 12
				destination_port lb[:vport].to_i
				profiles profiles_list
				default_persistence_profile '/Common/source_addr'
				enabled true
				action :create
			end
		end
	else
		if ["SSL","HTTPS","HTTP"].include?(lb[:vprotocol].upcase)
			f5_ltm_virtual_server "#{lb[:name]}" do
				vs_name lb[:name]
				f5 node.f5_host
				default_pool "#{lb[:sg_name]}"
				destination_address	"1.1.1.4"
				connection_limit 12
				destination_port lb[:vport].to_i
				profiles profiles_list
				enabled true
				action :create
			end
		else
			f5_ltm_virtual_server "#{lb[:name]}" do
				vs_name lb[:name]
				f5 node.f5_host
				default_pool "#{lb[:sg_name]}"
				destination_address	"1.1.1.4"
				connection_limit 12
				destination_port lb[:vport].to_i
				profiles profiles_list
				enabled true
				action :create
			end
		end					
	end
	dc_level_ip = node["ns_lbvserver_ip"]
end

# handle when no cloud-level vips
unless cloud_level_ip.nil?
  node.set["ns_lbvserver_ip"] = cloud_level_ip
  lbs = [] + node.loadbalancers + node.dcloadbalancers
else
  node.set["ns_lbvserver_ip"] = dc_level_ip    
  lbs = [] + node.dcloadbalancers
end
node.set["loadbalancers"] = lbs
