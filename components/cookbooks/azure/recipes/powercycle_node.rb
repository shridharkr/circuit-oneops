require 'azure_mgmt_compute'
require 'json'
require File.expand_path('../../libraries/azure_utils.rb', __FILE__)

::Chef::Recipe.send(:include, Azure::ARM::Compute)
::Chef::Recipe.send(:include, Azure::ARM::Compute::Models)

#set the proxy if it exists as a system prop
AzureCommon::AzureUtils.set_proxy_from_env(node)

#Get Credentials
include_recipe "azure::get_platform_rg_and_as"
include_recipe "azure::get_credentials"
include_recipe "azure::status_node"

  if node["status_result"] == "Success"
    begin
        client = ComputeManagementClient.new(node['azureCredentials'])
        client.subscription_id = node['subscriptionid']
        Chef::Log.info("hard reboot in progress, trying to POWER OFF ...")
        start_time = Time.now.to_i
        Chef::Log.info("Power off in progress")
        #Invoke poweroff method to poweroff the VM
        promise = client.virtual_machines.power_off(node['platform-resource-group'],node['vm_name'])
        result = promise.value!
        #Invoke start method to powerON the VM
        Chef::Log.info("Power on in progress")
        promise = client.virtual_machines.start(node['platform-resource-group'],node['vm_name'])
        result = promise.value!
        end_time = Time.now.to_i
        duration = end_time - start_time
        node.set["hard_reboot_result"]="Success"
        Chef::Log.info("VM HARD rebooted in #{duration} seconds")
    rescue  MsRestAzure::AzureOperationError =>e
        node.set["Hard_reboot_result"]="Error"
        Chef::Log.error("Error HARD rebooting VM #{node['vm_name']}")
        if e.body != nil
          error_response = e.body["error"]
          Chef::Log.error("Error Response code:" +error_response["code"])
          Chef::Log.error("Error Response message:" +error_response["message"])
        else
          Chef::Log.error("Error:"+e.inspect)
        end
  end
else
    node.set["hard_reboot_result"]="Error"
end
