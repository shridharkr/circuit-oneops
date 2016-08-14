require 'azure_mgmt_compute'
require 'azure_mgmt_network'
require 'azure_mgmt_storage'
require 'azure'
require File.expand_path('../../libraries/detachdisk.rb', __FILE__)
require File.expand_path('../../../azure_base/libraries/logger.rb', __FILE__)
require File.expand_path('../../../azure_base/libraries/utils.rb', __FILE__)


::Chef::Recipe.send(:include, Azure::ARM::Compute)
::Chef::Recipe.send(:include, Azure::ARM::Compute::Models)
::Chef::Recipe.send(:include, Azure::ARM::Network)
::Chef::Recipe.send(:include, Azure::ARM::Network::Models)
::Chef::Recipe.send(:include, Azure::ARM::Storage)
::Chef::Recipe.send(:include, Azure::ARM::Storage::Models)
::Chef::Recipe.send(:include, Azure::Core)
::Chef::Recipe.send(:include, Azure::Blob)

include_recipe 'azure::get_platform_rg_and_as'

Utils.set_proxy(node.workorder.payLoad.OO_CLOUD_VARS)
cloud_name = node['workorder']['cloud']['ciName']
tenant_id = node['workorder']['services']['storage'][cloud_name]['ciAttributes']['tenant_id']
client_id = node['workorder']['services']['storage'][cloud_name]['ciAttributes']['client_id']
client_secret = node['workorder']['services']['storage'][cloud_name]['ciAttributes']['client_secret']
subscription = node['workorder']['services']['storage'][cloud_name]['ciAttributes']['subscription']
storage_account_name = node['workorder']['services']['storage'][cloud_name]['ciAttributes']['storage_account']
instance_name = nil
if node.workorder.payLoad.has_key?("DependsOn")
 instance_name = node.workorder.payLoad.DependsOn[0]["ciAttributes"]["instance_name"]
 if instance_name != nil
   OOLog.info('instance_name:'+instance_name)
 end
end

node.set["azureCredentials"] = AzureStorage::AzureDatadisk.get_credentials(tenant_id,client_id,client_secret)

cloud_name = node[:workorder][:cloud][:ciName]
storage_service = node[:workorder][:services][:storage][cloud_name]
storage = storage_service["ciAttributes"]

storage_client = StorageManagementClient.new(node.azureCredentials)
storage_client.subscription_id = subscription



storage_account_keys= storage_client.storage_accounts.list_keys(storage.master_rg,storage.storage_account).value!
OOLog.info('  storage_account_keys : ' +   storage_account_keys.body.inspect)
key1 = storage_account_keys.body.key1
key2 = storage_account_keys.body.key2
dev_map = node.workorder.rfcCi.ciAttributes["device_map"]

dev_map.split(" ").each do |dev|
  dev_id = dev.split(":")[4]
  storage_account_name = dev.split(":")[1]
  component_name = dev.split(":")[2]
  dev_name = dev_id.split("/").last
  blobname = "#{storage.storage_account}-#{component_name}-datadisk-#{dev_name}.vhd"
  AzureStorage::AzureDatadisk.delete_disk(storage_account_name,key1,blobname,1)

end
if instance_name != nil
 OOLog.info('Detaching disk from VM')
 rgname = node['platform-resource-group']
 device_maps = node.workorder.rfcCi.ciAttributes["device_map"].split(" ")
 AzureStorage::AzureDatadisk.detach_disk_from_vm(instance_name,subscription,rgname,node['azureCredentials'],device_maps)
end
