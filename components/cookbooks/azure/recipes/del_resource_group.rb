require 'azure_mgmt_resources'

::Chef::Recipe.send(:include, Azure::ARM::Resources)
::Chef::Recipe.send(:include, Azure::ARM::Resources::Models)

include_recipe 'azure::get_credentials'


cloud_name = node[:workorder][:cloud][:ciName]
compute_service = node[:workorder][:services][:compute][cloud_name][:ciAttributes]
subscription_id = compute_service[:subscription]

location = compute_service[:location]
Chef::Log.info("Cloud Location: #{location}")

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'

# delete resource group; if need be
begin

  client = ResourceManagementClient.new(node[:azureCredentials])
  client.subscription_id = subscription_id

  existance_promise = client.resource_groups.check_existence(node['platform-resource-group'])
  response = existance_promise.value!
  result = response.body

  if result

    Chef::Log.info("Deleting Resource Group '#{node['platform-resource-group']}' ... ")
    start_time = Time.now.to_i
    promise = client.resource_groups.delete(node['platform-resource-group'])
    response = promise.value!
    result = response.body
    end_time = Time.now.to_i

    duration = end_time - start_time

    puts("Resource Group deleted in #{duration} seconds")

  else
    Chef::Log.info("Cannot delete Resource Group '#{node['platform-resource-group']}' does not exists ")
  end
rescue MsRestAzure::AzureOperationError => e
  Chef::Log.error("***FAULT:FATAL="+e.message)
  Chef::Log.error("AzureOperationError Response: #{e.response}")
  Chef::Log.error("AzureOperationError Body: #{e.body}")
  e = Exception.new('no backtrace')
  e.set_backtrace('')
  raise e
rescue Exception =>ex
  Chef::Log.error("***FAULT:FATAL="+ex.message)
  raise ex
end
