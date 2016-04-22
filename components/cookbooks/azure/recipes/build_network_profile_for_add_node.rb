# require File.expand_path('../../libraries/utils.rb', __FILE__)
# require File.expand_path('../../libraries/public_ip.rb', __FILE__)
# require File.expand_path('../../libraries/network_interface_card.rb', __FILE__)
# require File.expand_path('../../libraries/virtual_network.rb', __FILE__)
# require File.expand_path('../../libraries/subnet.rb', __FILE__)
# require File.expand_path('../../../azure_base/libraries/logger.rb', __FILE__)
require 'azure_mgmt_network'

# ::Chef::Recipe.send(:include, Utils)
# ::Chef::Recipe.send(:include, AzureNetwork)
# ::Chef::Recipe.send(:include, Azure::ARM::Network)
# ::Chef::Recipe.send(:include, Azure::ARM::Network::Models)

#################################################
OOLog.info('Building Network Profile for add_node...')

# Parse the node
cloud_name = node[:workorder][:cloud][:ciName]
compute_service =
  node[:workorder][:services][:compute][cloud_name][:ciAttributes]
location = compute_service[:location]
express_route_enabled = compute_service[:express_route_enabled]
subscription = compute_service[:subscription]
ci_id = node[:workorder][:rfcCi][:ciId]
OOLog.info('ci_id:'+ci_id.to_s)
resource_group_name = node['platform-resource-group']
OOLog.info('Resource group name: ' + resource_group_name)

# this is the resource group the preconfigured vnet will be in
master_resource_group_name = compute_service[:resource_group]
# preconfigured vnet name
preconfigured_network_name = compute_service[:network]

OOLog.info('Express Route is enabled: ' + express_route_enabled )

#TODO:validate data entry with regex.
# we get these values if it's NOT express route.
network_address = compute_service[:network_address].strip
subnet_address_list = (compute_service[:subnet_address]).split(',')
dns_list = (compute_service[:dns_ip]).split(',')

if express_route_enabled == 'true'
  ip_type = 'private'
else
  ip_type = 'public'
end

OOLog.info('ip_type: ' + ip_type)

# get the credentials needed to call Azure SDK
creds =
  AzureCommon::AzureUtils.get_credentials(compute_service[:tenant_id],
                                          compute_service[:client_id],
                                          compute_service[:client_secret]
                                         )

network_interface_cls =
  AzureNetwork::NetworkInterfaceCard.new(creds, subscription)
network_interface_cls.location = location
network_interface_cls.rg_name = resource_group_name
network_interface_cls.ci_id = ci_id

network_profile =
  network_interface_cls.build_network_profile(express_route_enabled,
                                              master_resource_group_name,
                                              preconfigured_network_name,
                                              network_address,
                                              subnet_address_list,
                                              dns_list,
                                              ip_type)

# set the ip on the node as the private ip
node.set['ip'] = network_interface_cls.private_ip

node.set['networkProfile'] = network_interface_cls.profile

# write the ip information to stdout for the inductor to pick up and use.
if ip_type == 'private'
  puts "***RESULT:private_ip="+node['ip']
  puts "***RESULT:public_ip="+node['ip']
  puts "***RESULT:dns_record="+node['ip']
else
  puts "***RESULT:private_ip="+node['ip']
end

OOLog.info("Exiting network profile")
