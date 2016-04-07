
require 'azure_mgmt_compute'
require 'azure_mgmt_storage'
require File.expand_path('../../../azure/libraries/azure_utils.rb', __FILE__)
require File.expand_path('../../libraries/attachdisk.rb', __FILE__)
# invoke recipe to get credentials
include_recipe "azure::get_credentials"


credentials = node['azureCredentials']

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'

AzureCommon::AzureUtils.set_proxy(node.workorder.payLoad.OO_CLOUD_VARS)

storage = nil
node.workorder.payLoad[:DependsOn].each do |dep|
  if dep["ciClassName"] =~ /Storage/
    storage = dep
    break
  end
end

if node.workorder.services.has_key?("storage")
  cloud_name = node[:workorder][:cloud][:ciName]
  storage_service = node[:workorder][:services][:storage][cloud_name]
  storage = storage_service["ciAttributes"]
  device_maps = storage['ciAttributes']['device_map'].split(" ")
  OOLog.info("device_maps"+device_maps)
  node.set[:device_maps] = device_maps

elsif storage != nil
  attr = storage[:ciAttributes]
  OOLog.info("attr"+attr.inspect())
  device_maps = attr['device_map'].split(" ")
  node.set[:device_maps] = device_maps
end

instance_name = node.workorder.payLoad.ManagedVia[0]["ciAttributes"]["instance_name"]
cloud_name = node[:workorder][:cloud][:ciName]
compute_service = node['workorder']['services']['compute'][cloud_name]['ciAttributes']
subscription_id = compute_service['subscription']
device_map = node[:device_maps]
rgname = node['platform-resource-group']

if device_map != nil
  OOLog.info("device_map "+device_map.inspect())
  dev_id = AzureStorage::AzureBlobs.attach_disk(instance_name,subscription_id,rgname,node['azureCredentials'],device_map)
else
  OOFatal.debug("device map is NULL. cannot proceed")
end
node.set["raid_device"] = dev_id
node.set["device"] = dev_id

