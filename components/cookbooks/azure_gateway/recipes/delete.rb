# **Rubocop Suppression**
# rubocop:disable LineLength

require File.expand_path('../../libraries/application_gateway.rb', __FILE__)
require File.expand_path('../../../azure/libraries/public_ip.rb', __FILE__)
require 'azure_mgmt_network'

::Chef::Recipe.send(:include, Utils)
::Chef::Recipe.send(:include, Azure::ARM::Network)
::Chef::Recipe.send(:include, Azure::ARM::Network::Models)
::Chef::Recipe.send(:include, AzureNetwork)

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'

def get_credentials(tenant_id, client_id, client_secret)
  # Create authentication objects
  token_provider = MsRestAzure::ApplicationTokenProvider.new(tenant_id, client_id, client_secret)
  if !token_provider.nil?
    credentials = MsRest::TokenCredentials.new(token_provider)
    return credentials
  else
    msg = 'Could not retrieve azure credentials'
    Chef::Log.error(msg)
    puts "***FAULT:FATAL=#{msg}"
    raise(msg)
  end
rescue MsRestAzure::AzureOperationError
  msg = 'Error acquiring authentication token from azure'
  # puts "***FAULT:FATAL=#{msg}"
  Chef::Log.error(msg)
  raise(msg)
end

cloud_name = node.workorder.cloud.ciName
ag_service = nil
if !node.workorder.services['lb'].nil? && !node.workorder.services['lb'][cloud_name].nil?
  ag_service = node.workorder.services['lb'][cloud_name]
end

if ag_service.nil?
  Chef::Log.error('missing ag service')
  exit 1
end

platform_name = node.workorder.box.ciName
environment_name = node.workorder.payLoad.Environment[0]['ciName']
assembly_name = node.workorder.payLoad.Assembly[0]['ciName']
org_name = node.workorder.payLoad.Organization[0]['ciName']
security_group = "#{environment_name}.#{assembly_name}.#{org_name}"
resource_group_name = node['platform-resource-group']
subscription_id = ag_service[:ciAttributes]['subscription']
location = ag_service[:ciAttributes][:location]

asmb_name = assembly_name.gsub(/-/, '').downcase
plat_name = platform_name.gsub(/-/, '').downcase
env_name = environment_name.gsub(/-/, '').downcase
ag_name = "ag-#{plat_name}"

tenant_id = ag_service[:ciAttributes][:tenant_id]
client_id = ag_service[:ciAttributes][:client_id]
client_secret = ag_service[:ciAttributes][:client_secret]

credentials = get_credentials(tenant_id, client_id, client_secret)
application_gateway = AzureNetwork::Gateway.new(credentials, subscription_id)

public_ip_name = Utils.get_component_name('lb_publicip', node.workorder.rfcCi.ciId)

Chef::Log.info("Cloud Name: #{cloud_name}")
Chef::Log.info("Org: #{org_name}")
Chef::Log.info("Assembly: #{asmb_name}")
Chef::Log.info("Platform: #{platform_name}")
Chef::Log.info("Environment: #{env_name}")
Chef::Log.info("Location: #{location}")
Chef::Log.info("Security Group: #{security_group}")
Chef::Log.info("Resource Group: #{resource_group_name}")
Chef::Log.info("Application Gateway: #{ag_name}")

application_gateway.delete(resource_group_name, ag_name)
public_ip_obj = AzureNetwork::PublicIp.new(credentials, subscription_id)
public_ip_obj.delete(resource_group_name, public_ip_name)
