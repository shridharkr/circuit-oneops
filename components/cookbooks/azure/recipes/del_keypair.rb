require File.expand_path('../../libraries/azure_utils.rb', __FILE__)

#set the proxy if it exists as a cloud var
AzureCommon::AzureUtils.set_proxy(node.workorder.payLoad.OO_CLOUD_VARS)

# Delete Resource Group
include_recipe 'azure::del_resource_group'

# NOTE: There is no recipe for deleting Availability Set.
# An Availability Set is created as part of a Resource Group.
# Therefore, deleting a Resource Group will delete ALL
# resources within it. Thus, deleting any Availability Sets
