require 'azure_mgmt_compute'
require 'json'
require File.expand_path('../../libraries/azure_utils.rb', __FILE__)

::Chef::Recipe.send(:include, Azure::ARM::Compute)
::Chef::Recipe.send(:include, Azure::ARM::Compute::Models)

#set the proxy if it exists as a system prop
AzureCommon::AzureUtils.set_proxy_from_env(node)

include_recipe "azure::get_platform_rg_and_as"
include_recipe "azure::get_credentials"
include_recipe "azure::status_node"

if node["status_result"] == "Success"
  begin
    client = ComputeManagementClient.new(node['azureCredentials'])
    client.subscription_id = node['subscriptionid']
    Chef::Log.info("reboot in progress")
    start_time = Time.now.to_i
    promise = client.virtual_machines.restart(node['platform-resource-group'],node['vm_name'])
    result = promise.value!
    end_time = Time.now.to_i
    duration = end_time - start_time
    Chef::Log.error("VM rebooted in #{duration} seconds")
    node.set["reboot_result"]="Success"
  rescue  MsRestAzure::AzureOperationError => e
    node.set["reboot_result"]="Error"
    Chef::Log.error("Error rebooting VM #{vm_name}")
    if e.body != nil
      error_response = e.body["error"]
      Chef::Log.error("Error Response code:" +error_response["code"])
      Chef::Log.error("Error Response message:" +error_response["message"])
    else
      Chef::Log.error("Error:"+e.inspect)
    end
  end
else
  node.set["reboot_result"]="Error"
end
