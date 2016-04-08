require 'azure_mgmt_compute'
require 'json'
require File.expand_path('../../libraries/azure_utils.rb', __FILE__)

::Chef::Recipe.send(:include, Azure::ARM::Compute)
::Chef::Recipe.send(:include, Azure::ARM::Compute::Models)

#set the proxy if it exists as a system prop
AzureCommon::AzureUtils.set_proxy_from_env(node)

include_recipe 'azure::get_platform_rg_and_as'
include_recipe "azure::get_credentials"

begin
      client = ComputeManagementClient.new(node['azureCredentials'])
      client.subscription_id = node['subscriptionid']
      promise = client.virtual_machines.get(node['platform-resource-group'],node['vm_name'])
      result = promise.value!
      node.set["status_result"]="Success"
      node.set["server_info"]=result.body
      Chef::Log.info("server info: " + node.server_info.inspect.gsub(/\n|\<|\>|\{|\}/,""))
rescue  MsRestAzure::AzureOperationError =>e
      Chef::Log.error("Error getting VM status for #{vm_name}")
      node.set["status_result"]="Error"
      if e.body != nil
        error_response = e.body["error"]
        Chef::Log.error("Error Response code:" +error_response["code"])
        Chef::Log.error("Error Response message:" +error_response["message"])
      else
        Chef::Log.error("Error:"+e.inspect)
      end
end
