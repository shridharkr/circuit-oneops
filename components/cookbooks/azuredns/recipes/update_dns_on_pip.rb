# rubocop:disable LineLength

::Chef::Recipe.send(:include, AzureNetwork)
::Chef::Recipe.send(:include, Utils)
::Chef::Recipe.send(:include, Azure::ARM::Network)
::Chef::Recipe.send(:include, Azure::ARM::Network::Models)
# get credentials
include_recipe 'azure::get_credentials'

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'
Chef::Log.info("azuredns:update_dns_on_pip.rb - platform-resource-group is: #{node['platform-resource-group']}")

cloud_name = node['workorder']['cloud']['ciName']
dns_attributes = node['workorder']['services']['dns'][cloud_name]['ciAttributes']
subscription = dns_attributes['subscription']
resource_group = node['platform-resource-group']
credentials = node['azureCredentials']
zone_name = dns_attributes['zone']
zone_name = zone_name.split('.').reverse.join('.').partition('.').last.split('.').reverse.join('.')
zone_name = zone_name.tr('.', '-')

public_ip = AzureDns::PublicIp.new(resource_group, credentials, subscription, zone_name)

domain_name_label = public_ip.update_dns(node)
node.set['domain_name_label'] = domain_name_label unless domain_name_label.nil?
