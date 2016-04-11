require File.expand_path('../../libraries/public_ip.rb', __FILE__)
require File.expand_path('../../../azure/libraries/azure_utils', __FILE__)
require File.expand_path('../../../azure_base/libraries/logger.rb', __FILE__)
require 'azure_mgmt_network'

::Chef::Recipe.send(:include, AzureCommon)



cloud_name = node['workorder']['cloud']['ciName']
dns_attributes = node['workorder']['services']['dns'][cloud_name]['ciAttributes']
tenant_id = dns_attributes['tenant_id']
client_id = dns_attributes['client_id']
client_secret = dns_attributes['client_secret']
subscription = dns_attributes['subscription']

credentials = AzureCommon::AzureUtils.get_credentials(tenant_id, client_id, client_secret)

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'
OOLog.info("azuredns:update_dns_on_pip.rb - platform-resource-group is: #{node['platform-resource-group']}")
resource_group = node['platform-resource-group']

zone_name = dns_attributes['zone']
zone_name = zone_name.split('.').reverse.join('.').partition('.').last.split('.').reverse.join('.')
zone_name = zone_name.tr('.', '-')

public_ip = AzureDns::PublicIp.new(resource_group, credentials, subscription, zone_name)

domain_name_label = public_ip.update_dns(node)
node.set['domain_name_label'] = domain_name_label unless domain_name_label.nil?
