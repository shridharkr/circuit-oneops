require 'azure_mgmt_compute'

::Chef::Recipe.send(:include, Azure::ARM::Compute)
::Chef::Recipe.send(:include, Azure::ARM::Compute::Models)

cloud_name = node['workorder']['cloud']['ciName']
Chef::Log.info("Cloud Name: #{cloud_name}")
compute_service = node['workorder']['services']['compute'][cloud_name]['ciAttributes']

Chef::Log.info("Subscription ID: #{compute_service['subscription']}")

# invoke recipe to get credentials
include_recipe "azure::get_credentials"

# create the VM in the platform specific resource group and availability set
client = ComputeManagementClient.new(node['azureCredentials'])
client.subscription_id = compute_service['subscription']

begin
  platform_resource_group = node['platform-resource-group']
  platform_availability_set_name = node['platform-availability-set']
  promise = client.availability_sets.get(platform_resource_group, platform_availability_set_name).value!
  node.set['availability_set'] = promise.body
rescue  MsRestAzure::AzureOperationError => e
  Chef::Log.error("***FAULT:Error getting availability set for resource group: #{resource_group_name} and availability set: #{availability_set_name} , exception=#{e.message}")
  e = Exception.new('no backtrace')
  e.set_backtrace('')
  raise e
rescue Exception => ex
  Chef::Log.error("***FAULT:FATAL=#{ex.message}")
  ex = Exception.new('no backtrace')
  ex.set_backtrace('')
  raise ex
end

Chef::Log.info("Exiting get availability set")
