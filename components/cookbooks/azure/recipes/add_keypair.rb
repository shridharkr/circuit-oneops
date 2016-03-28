require 'azure_mgmt_resources'
require File.expand_path('../../libraries/azure_utils.rb', __FILE__)

#::Chef::Recipe.send(:include, AzureCommon)

#set the proxy if it exists as a cloud var
AzureCommon::AzureUtils.set_proxy(node.workorder.payLoad.OO_CLOUD_VARS)

# Setup Azure credentials
include_recipe 'azure::get_credentials'

# Create Resource Group
include_recipe 'azure::add_resource_group'

# Create Availability Set
include_recipe 'azure::add_availability_set'

Chef::Log.info("Exiting add keypair")
