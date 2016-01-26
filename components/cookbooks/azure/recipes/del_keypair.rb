
# Delete Resource Group
include_recipe 'azure::del_resource_group'

# NOTE: There is no recipe for deleting Availability Set.
# An Availability Set is created as part of a Resource Group.
# Therefore, deleting a Resource Group will delete ALL
# resources within it. Thus, deleting any Availability Sets
