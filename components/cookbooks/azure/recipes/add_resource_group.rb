require 'azure_mgmt_resources'

::Chef::Recipe.send(:include, Azure::ARM::Resources)
::Chef::Recipe.send(:include, Azure::ARM::Resources::Models)

cloud_name = node[:workorder][:cloud][:ciName]
compute_service = node[:workorder][:services][:compute][cloud_name][:ciAttributes]
subscription_id = compute_service[:subscription]

location = compute_service[:location]
node.set['cloud_location'] = location
Chef::Log.info("Cloud Location: #{location}")

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'

# add resource group; if need be
begin
  client = ResourceManagementClient.new(node[:azureCredentials])
  client.subscription_id = subscription_id

  # First, check if resource group is already created
  begin
    existance_promise = client.resource_groups.check_existence(node['platform-resource-group'])
    response = existance_promise.value!
    result = response.body
  rescue => ex
    puts "***FAULT:FATAL="+ex.message
    raise ex
  end

  if result
    Chef::Log.info("Resource Group '#{node['platform-resource-group']}' already exists. No need to create. ")
  else
    resource_group = ResourceGroup.new
    resource_group.location = location

    Chef::Log.info("Creating Resource Group '#{node['platform-resource-group']}' ... ")
    start_time = Time.now.to_i
    promise = client.resource_groups.create_or_update(node['platform-resource-group'], resource_group)
    response = promise.value!
    result = response.body
    end_time = Time.now.to_i

    duration = end_time - start_time

    puts("Resource Group created in #{duration} seconds")
  end
rescue MsRestAzure::AzureOperationError => e
  puts "***FAULT:FATAL="+e.message
  Chef::Log.error("AzureOperationError Response: #{e.response}")
  Chef::Log.error("AzureOperationError Body: #{e.body}")
  e = Exception.new('no backtrace')
  e.set_backtrace('')
  raise e
rescue Exception =>ex
  puts "***FAULT:FATAL="+ex.message
  raise ex
end

Chef::Log.info("Exiting add resource group")
