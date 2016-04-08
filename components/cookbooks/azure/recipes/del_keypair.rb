# NOTE: There is no recipe for deleting Availability Set.
# An Availability Set is created as part of a Resource Group.
# Therefore, deleting a Resource Group will delete ALL
# resources within it. Thus, deleting any Availability Sets

require 'azure_mgmt_resources'
require File.expand_path('../../libraries/availability_set.rb', __FILE__)
require File.expand_path('../../libraries/resource_group.rb', __FILE__)
require File.expand_path('../../../azure_base/libraries/logger.rb', __FILE__)

::Chef::Recipe.send(:include, AzureCompute)
::Chef::Recipe.send(:include, AzureResources)

cloud_name = node[:workorder][:cloud][:ciName]
compute_service =
  node[:workorder][:services][:compute][cloud_name][:ciAttributes]

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'
rg_name = node['platform-resource-group']
location = compute_service['location']

# Delete Resource Group
#include_recipe 'azure::del_resource_group'
resource_group = AzureResources::ResourceGroup.new(compute_service)

#First check to see if the resource group exists.
rg = resource_group.get(rg_name)
if rg
  OOLog.info("Deleting Resource Group '#{rg_name}' ... ")
  resource_group.delete(rg_name)
else
  # it doesn't exist.
  OOLog.info("Resource Group '#{rg_name}' doesn't exists.")
end
