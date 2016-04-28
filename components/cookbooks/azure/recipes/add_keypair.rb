require 'azure_mgmt_resources'
require 'azure_mgmt_compute'
require File.expand_path('../../libraries/availability_set.rb', __FILE__)
require File.expand_path('../../libraries/resource_group.rb', __FILE__)
require File.expand_path('../../../azure_base/libraries/logger.rb', __FILE__)
require File.expand_path('../../libraries/azure_utils.rb', __FILE__)

::Chef::Recipe.send(:include, AzureCompute)
::Chef::Recipe.send(:include, AzureResources)

#set the proxy if it exists as a cloud var
AzureCommon::AzureUtils.set_proxy(node[:workorder][:payLoad][:OO_CLOUD_VARS])

# get all necessary info from node
cloud_name = node[:workorder][:cloud][:ciName]
compute_service =
  node[:workorder][:services][:compute][cloud_name][:ciAttributes]
nsPathParts = node[:workorder][:rfcCi][:nsPath].split('/')
org = nsPathParts[1]
assembly = nsPathParts[2]
environment = nsPathParts[3]
platform_ci_id = node[:workorder][:box][:ciId]
location = compute_service[:location]

resource_group = AzureResources::ResourceGroup.new(compute_service)

# get the resource group name
rg_name =
  AzureResources::ResourceGroup.get_name(org,
                                         assembly,
                                         platform_ci_id,
                                         environment,
                                         location)

# availability set name will be the same as the resource group name
as_name = rg_name

#First check to see if the resource group exists.
rg = resource_group.get(rg_name)
if rg
  OOLog.info("Resource Group '#{rg_name}' already exists. No need to create.")
else
  # it doesn't exist, so add it.
  OOLog.info("Creating Resource Group '#{rg_name}' for location '#{location}'.")
  resource_group.add(rg_name, location)
end

# get the availability set to use
availability_set = AzureCompute::AvailabilitySet.new(compute_service)
# Create Availability Set
availability_set.add(rg_name, as_name, location)

OOLog.info('Exiting add keypair')
