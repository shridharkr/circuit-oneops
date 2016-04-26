require 'azure_mgmt_network'

require File.expand_path('../../libraries/utils.rb', __FILE__)

::Chef::Recipe.send(:include, Utils)
::Chef::Recipe.send(:include, Azure::ARM::Network)
::Chef::Recipe.send(:include, Azure::ARM::Network::Models)

def create_public_ip_address(network_client, resource_group_name, public_ip_address)
  begin
    public_ip_if= network_client.public_ip_addresses.create_or_update(resource_group_name, public_ip_address.name, public_ip_address)
    result = public_ip_if.value!
  rescue MsRestAzure::AzureOperationError => ex
    OOLog.error('***FAULT:FATAL=creating/updating ' + public_ip_address.name + ' in resource group: ' + resource_group_name)
    OOLog.error('***FAULT:FATAL=' + ex.body.to_s)
    exit 1
  end

  return result.body
end

def define_public_ip_address(location, ci_id)
  public_ip_configs = PublicIpAddressPropertiesFormat.new
  public_ip_configs.public_ipallocation_method = IpAllocationMethod::Dynamic

  public_ip_address = PublicIpAddress.new
  public_ip_address.location = location
  nameutil = Utils::NameUtils.new()
  public_ip_address.name = nameutil.get_component_name("publicip",ci_id)
  public_ip_address.properties = public_ip_configs
  OOLog.info('Public IP name is: ' + public_ip_address.name)
  return public_ip_address
end

def create_network_interface(network_client, resource_group_name, nic_name, network_interface)
  OOLog.info('Creating/Updating nic name: ' + nic_name)
  resource_group_name = node.set['platform-resource-group'] #TODO: delete this line after test
  begin
    nic = network_client.network_interfaces.create_or_update(resource_group_name, nic_name, network_interface)
    result = nic.value!
  rescue MsRestAzure::AzureOperationError => e
    OOLog.error('***FAULT:FATAL=creating/updating ' + nic_name + ' in resource group: ' + resource_group_name)
    OOLog.error('***FAULT:FATAL=' + e.body.to_s)
    exit 1
  end

  return result.body
end

def define_network_interface(nic_ip_config, location, ci_id)
  network_interface_props = NetworkInterfacePropertiesFormat.new
  network_interface_props.ip_configurations = [nic_ip_config]

  network_interface = NetworkInterface.new
  network_interface.location = location
  nameutil = Utils::NameUtils.new()
  network_interface.name = nameutil.get_component_name("nic",ci_id)
  network_interface.properties = network_interface_props

  OOLog.info('Network Interface name is: ' + network_interface.name)
  return network_interface
end

def define_nic_ip_config(ip_type, ci_id, subnet, network_client, resource_group_name, location)
  nic_ip_config_props = NetworkInterfaceIpConfigurationPropertiesFormat.new
  nic_ip_config_props.private_ipallocation_method = IpAllocationMethod::Dynamic
  nic_ip_config_props.subnet = subnet

  if ip_type == 'public'
    public_ip_address = define_public_ip_address(location, ci_id)
    public_ip_if= create_public_ip_address(network_client, resource_group_name, public_ip_address)
    nic_ip_config_props.public_ipaddress = public_ip_if
  end
  nic_ip_config = NetworkInterfaceIpConfiguration.new
  nameutil = Utils::NameUtils.new()
  nic_ip_config.name = nameutil.get_component_name("privateip",ci_id)
  nic_ip_config.properties = nic_ip_config_props
  OOLog.info('NIC IP name is: ' + nic_ip_config.name)
  return nic_ip_config
end

def get_subnet_with_available_ips(subnets, express_route_enabled)

  subnets.each do |subnet|
    OOLog.info('checking for ip availability in ' + subnet.name)
    address_prefix = subnet.properties.address_prefix

    if express_route_enabled == 'true'
      total_num_of_ips_possible = (2 ** (32 - (address_prefix.split('/').last.to_i)))-5 #Broadcast(1)+Gateway(1)+azure express routes(3) = 5
    else
      total_num_of_ips_possible = (2 ** (32 - (address_prefix.split('/').last.to_i)))-2 #Broadcast(1)+Gateway(1)
    end
    OOLog.info("Total number of ips possible is: #{total_num_of_ips_possible.to_s}")

    if subnet.properties.ip_configurations.nil?
      no_ips_inuse = 0
    else
      no_ips_inuse = subnet.properties.ip_configurations.length
    end
    OOLog.info("Num of ips in use: #{no_ips_inuse.to_s}")

    remaining_ips = total_num_of_ips_possible - (no_ips_inuse)
    if remaining_ips == 0
      OOLog.info("No IP address remaining in the Subnet '#{subnet.name}'")
      OOLog.info("Total number of subnets(subnet_name_list.count) = #{(subnets.count).to_s}")
      OOLog.info('checking the next subnet')
      next #check the next subnet
    else
      return subnet
    end
  end

  OOLog.error('***FAULT:FATAL=- No IP address available in any of the Subnets allocated. limit exceeded')
  exit 1
end

def define_subnet_objects(network_name, subnet_address_list)
  sub_nets = Array.new
  for i in 0..subnet_address_list.length-1
    OOLog.info('subnet_address_list[' + i.to_s + ']: ' + subnet_address_list[i].strip)
    subnet_properties = SubnetPropertiesFormat.new
    subnet_properties.address_prefix = subnet_address_list[i].strip

    subnet = Subnet.new
    subnet.name = 'subnet_' + i.to_s + '_' + network_name
    subnet.properties = subnet_properties
    sub_nets.push(subnet)
    OOLog.info('Subnet name is: ' + subnet.name)
  end

  return sub_nets
end

def define_network_object(location, network_name, network_address, dns_list, subnet_address_list)
  OOLog.info('network_address: ' + network_address)
  address_space = AddressSpace.new
  address_space.address_prefixes = [network_address]

  ns_list = Array.new
  for i in 0..dns_list.length-1
    OOLog.info('dns address[' + i.to_s + ']: ' + dns_list[i].strip)
    ns_list.push(dns_list[i].strip)
  end
  dhcp_options = DhcpOptions.new
  if ns_list != nil
    dhcp_options.dns_servers = ns_list
  end

  sub_nets = define_subnet_objects(network_name, subnet_address_list)

  virtual_network_properties = VirtualNetworkPropertiesFormat.new
  virtual_network_properties.address_space = address_space
  virtual_network_properties.dhcp_options = dhcp_options
  virtual_network_properties.subnets = sub_nets

  virtual_network = VirtualNetwork.new
  virtual_network.location = location
  virtual_network.properties = virtual_network_properties

  return virtual_network
end

def create_update_network(network_client, resource_group_name, location, network_name, network_address, dns_list, subnet_address_list)
  virtual_network = define_network_object(location, network_name, network_address, dns_list, subnet_address_list)

  OOLog.info('Creating/Updating network name: ' + network_name)
  begin
    promise = network_client.virtual_networks.create_or_update(resource_group_name, network_name, virtual_network)
    network = promise.value!
    OOLog.info('Successfully created/updated network name: ' + network_name)
  rescue MsRestAzure::AzureOperationError => e
    OOLog.error('***FAULT:FATAL=creating/updating ' + network_name + ' in resource group: ' + resource_group_name)
    OOLog.error('***FAULT:FATAL=' + e.body.to_s)
    exit 1
  end

  return network
end

def get_network(network_client, resource_group_name, network_name)
  OOLog.info('Searching if network ' + network_name + ' already exist')
  begin
    promise = network_client.virtual_networks.get(resource_group_name, network_name)
    network = promise.value!
  rescue MsRestAzure::AzureOperationError => e
    OOLog.error('Network ' + network_name + ' not found')
    OOLog.error('Error: ' + e.body.to_s)
    return nil
  end

  return network
end
#################################################

#################################################
cloud_name = node['workorder']['cloud']['ciName']
compute_service = node['workorder']['services']['compute'][cloud_name]['ciAttributes']

network_client = NetworkResourceProviderClient.new(node['azureCredentials'])
network_client.subscription_id = compute_service['subscription']

OOLog.info('Building Network Profile for add_node...')
location = compute_service['location'].gsub(" ","").downcase
express_route_enabled = compute_service['express_route_enabled']
if express_route_enabled == 'true'
  ip_type = 'private'
else
  ip_type = 'public'
end
resource_group_name = node.set['platform-resource-group']
OOLog.info('Resource group name: ' + resource_group_name)

if express_route_enabled == 'true'
  master_resource_group_name = compute_service['resource_group']
  network_name = compute_service['network']
  OOLog.info('Express Route is enabled: ' + express_route_enabled )
  OOLog.info('Master Resource group name: ' + master_resource_group_name)
  OOLog.info('Network name: ' + network_name)
  network = get_network(network_client, master_resource_group_name, network_name)
  if network == nil
    OOLog.error('***FAULT:FATAL=Express route connections to azure require the network and subnet address ranges to be preconfigured.')
    exit 1
  end
else
  network_name = 'vnet_'+ resource_group_name
  network = get_network(network_client, resource_group_name, network_name)
  if(network == nil)
    network_address = compute_service['network_address'].strip
    subnet_address_list = (compute_service['subnet_address']).split(',')
    dns_list = (compute_service['dns_ip']).split(',') #TODO:validate data entry
    OOLog.info('Network name: ' + network_name)
    OOLog.info('ip_type: ' + ip_type)
    network = create_update_network(network_client, resource_group_name, location, network_name, network_address, dns_list, subnet_address_list)
  end
end

subnet = get_subnet_with_available_ips(network.body.properties.subnets, express_route_enabled)
ci_id = node['workorder']['rfcCi']['ciId']
OOLog.info('ci_id:'+ci_id.to_s)
nic_ip_config = define_nic_ip_config(ip_type, ci_id, subnet, network_client, resource_group_name, location)
network_interface = define_network_interface(nic_ip_config, location, ci_id)
nic = create_network_interface(network_client, resource_group_name, network_interface.name, network_interface)
network_interface.id = nic.id
private_ip = nic.properties.ip_configurations[0].properties.private_ipaddress
OOLog.info('Private IP is: ' + private_ip)
node.set['ip'] = private_ip

network_profile = NetworkProfile.new
network_profile.network_interfaces = [network_interface]
node.set['networkProfile'] = network_profile

if ip_type == 'private'
  puts "***RESULT:private_ip="+node['ip']
  puts "***RESULT:public_ip="+node['ip']
  puts "***RESULT:dns_record="+node['ip']
else
  puts "***RESULT:private_ip="+node['ip']
end

OOLog.info("Exiting network profile")
