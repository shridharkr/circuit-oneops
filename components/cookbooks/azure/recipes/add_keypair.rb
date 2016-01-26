require 'azure_mgmt_resources'

# Setup Azure credentials
include_recipe 'azure::get_credentials'

# Create Resource Group
include_recipe 'azure::add_resource_group'

# Create Availability Set
include_recipe 'azure::add_availability_set'

Chef::Log.info("Exiting add keypair")
