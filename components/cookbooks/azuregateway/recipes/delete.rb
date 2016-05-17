# **Rubocop Suppression**
# rubocop:disable LineLength

require File.expand_path('../../../azure/libraries/utils.rb', __FILE__)
require File.expand_path('../../libraries/application_gateway.rb', __FILE__)
require File.expand_path('../../../azure/libraries/public_ip.rb', __FILE__)
require 'azure_mgmt_network'

::Chef::Recipe.send(:include, Utils)
::Chef::Recipe.send(:include, Azure::ARM::Network)
::Chef::Recipe.send(:include, Azure::ARM::Network::Models)
::Chef::Recipe.send(:include, AzureNetwork)

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'
include_recipe 'initialize_attributes_from_node'

begin
  credentials = AzureCommon::AzureUtils.get_credentials(tenant_id, client_id, client_secret)
  application_gateway = AzureNetwork::Gateway.new(resource_group_name, ag_name, credentials, subscription_id)

  nameutil = Utils::NameUtils.new
  public_ip_name = nameutil.get_component_name('lb_publicip', node.workorder.rfcCi.ciId)

  application_gateway.delete
  public_ip_obj = AzureNetwork::PublicIp.new(credentials, subscription_id)
  public_ip_obj.delete(resource_group_name, public_ip_name)
rescue => e
  OOLog.fatal("Error deleting Application Gateway: #{e.message}")
end
