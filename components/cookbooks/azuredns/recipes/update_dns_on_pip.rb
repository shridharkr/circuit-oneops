require File.expand_path('../../../azure/libraries/azure_utils', __FILE__)
require File.expand_path('../../../azuredns/libraries/public_ip', __FILE__)

# ::Chef::Recipe.send(:include, AzureNetwork)
# ::Chef::Recipe.send(:include, Utils)
# ::Chef::Recipe.send(:include, Azure::ARM::Network)
# ::Chef::Recipe.send(:include, Azure::ARM::Network::Models)

#set the proxy if it exists as a cloud var
AzureCommon::AzureUtils.set_proxy(node.workorder.payLoad.OO_CLOUD_VARS)

# get credentials
include_recipe 'azure::get_credentials'

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'
OOLog.info("azuredns:update_dns_on_pip.rb - platform-resource-group is: #{node['platform-resource-group']}")

cloud_name = node['workorder']['cloud']['ciName']
dns_attributes = node['workorder']['services']['dns'][cloud_name]['ciAttributes']
tenant_id = dns_attributes['tenant_id']
client_id = dns_attributes['client_id']
client_secret = dns_attributes['client_secret']
subscription = dns_attributes['subscription']
resource_group = node['platform-resource-group']
credentials = AzureCommon::AzureUtils.get_credentials(tenant_id, client_id, client_secret)

zone_name = dns_attributes['zone']
zone_name = zone_name.split('.').reverse.join('.').partition('.').last.split('.').reverse.join('.')
zone_name = zone_name.tr('.', '-')

public_ip = AzureDns::PublicIp.new(resource_group, credentials, subscription, zone_name)

domain_name_label = public_ip.update_dns(node)
node.set['domain_name_label'] = domain_name_label unless domain_name_label.nil?
