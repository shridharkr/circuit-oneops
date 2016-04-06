require 'azure_mgmt_resources'
require File.expand_path('../../libraries/availability_set.rb', __FILE__)
require File.expand_path('../../libraries/resource_group.rb', __FILE__)
require File.expand_path('../../../azure_base/libraries/logger.rb', __FILE__)

::Chef::Recipe.send(:include, AzureCompute)
::Chef::Recipe.send(:include, AzureResources)

cloud_name = node[:workorder][:cloud][:ciName]
compute_service =
  node[:workorder][:services][:compute][cloud_name][:ciAttributes]

# Setup Azure credentials
##  TODO: need to remove this when resource group is refactored.
#include_recipe 'azure::get_credentials'

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'
rg_name = node['platform-resource-group']
as_name = node['platform-availability-set']
location = compute_service['location']

# Create Resource Group
#include_recipe 'azure::add_resource_group'
resource_group = AzureResources::ResourceGroup.new(compute_service)
#First check to see if the resource group exists.
rg = resource_group.get(rg_name)
if rg
  OOLog.info("Resource Group '#{rg_name}' already exists. No need to create.")
else
  # it doesn't exist, so add it.
  OOLog.info("Creating Resource Group '#{rg_name}' ... ")
  resource_group.add(rg_name, location)
end

# get the availability set to use
availability_set = AzureCompute::AvailabilitySet.new(compute_service)
# Create Availability Set
availability_set.add(rg_name, as_name, location)

OOLog.info('Exiting add keypair')

OOLog.fatal('Exit for Testing')
