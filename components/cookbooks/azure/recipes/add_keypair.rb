require 'azure_mgmt_resources'

cloud_name = node[:workorder][:cloud][:ciName]
compute_service =
  node[:workorder][:services][:compute][cloud_name][:ciAttributes]

# Setup Azure credentials
##  TODO: need to remove this when resource group is refactored.
include_recipe 'azure::get_credentials'

# Create Resource Group
include_recipe 'azure::add_resource_group'

# get the availability set to use
availability_set = AzureCompute::AvailabilitySet.new(compute_service)
# Create Availability Set
availability_set.add(node['platform-resource-group'],
                     node['platform-availability-set'],
                     compute_service['location'])

Chef::Log.info('Exiting add keypair')
