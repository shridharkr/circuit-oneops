require File.expand_path('../../libraries/network_security_group.rb', __FILE__)

::Chef::Recipe.send(:include, AzureNetwork)
::Chef::Recipe.send(:include, Azure::ARM::Network)
::Chef::Recipe.send(:include, Azure::ARM::Network::Models)
include_recipe 'azure::get_credentials'
include_recipe 'azure::get_platform_rg_and_as'

cloud_name = node['workorder']['cloud']['ciName']
subscription = node['workorder']['services']['compute'][cloud_name]['ciAttributes']['subscription']
location = node['workorder']['services']['compute'][cloud_name]['ciAttributes']['location']
credentials = node['azureCredentials']
resource_group_name = node['platform-resource-group']
network_security_group_name = node['name']
node['secgroup']['inbound']

# Creating security rules objects
nsg = AzureNetwork::NetworkSecurityGroup.new(credentials, subscription)
rules = node['secgroup']['inbound'].tr('"[]\\', '').split(',')
sec_rules = []
priority = 100
reg_ex = /\d+\s\d+\s([A-Za-z]+|\*)\s\S+/
rules.each do |item|
  if !reg_ex.match(item)
    raise "#{item} is not a valid security rule"
  end
  item2 = item.split(' ')
  security_rule_access = SecurityRuleAccess::Allow
  security_rule_description = node['secgroup']['description']
  security_rule_destination_addres_prefix = item2[3]
  security_rule_destination_port_range = item2[1].to_i
  security_rule_direction = SecurityRuleDirection::Inbound
  security_rule_priority = priority
  case item2[2].downcase
  when 'tcp'
    security_rule_protocol = SecurityRuleProtocol::Tcp
  when 'udp'
    security_rule_protocol = SecurityRuleProtocol::Udp
  else
    security_rule_protocol = SecurityRuleProtocol::Asterisk
  end
  security_rule_provisioning_state = nil
  security_rule_source_addres_prefix = '0.0.0.0/0'
  security_rule_source_port_range = item2[0].to_i
  security_rule_name = network_security_group_name + '-' + priority.to_s
  sec_rules << AzureNetwork::NetworkSecurityGroup.create_rule_properties(security_rule_name, security_rule_access,security_rule_description, security_rule_destination_addres_prefix, security_rule_destination_port_range, security_rule_direction, security_rule_priority, security_rule_protocol, security_rule_provisioning_state, security_rule_source_addres_prefix, security_rule_source_port_range)
  priority += 100
end

parameters = NetworkSecurityGroup.new
parameters.location = location

nsg_props = NetworkSecurityGroupPropertiesFormat.new
nsg_props.security_rules = sec_rules
parameters.properties = nsg_props

nsg_result = nsg.create_update(resource_group_name, network_security_group_name, parameters)

if !nsg_result.nil?
  Chef::Log.info("The network security group has been created\n\rid: '#{nsg_result.id}'\n\r'#{nsg_result.location}'\n\r'#{nsg_result.name}'\n\r'#{nsg_result.type}'")
else
  raise 'Error creating network security group'
end
