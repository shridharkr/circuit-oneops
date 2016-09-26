require 'azure_mgmt_compute'
require 'azure_mgmt_network'
require 'azure_mgmt_storage'
require 'azure'
require File.expand_path('../../libraries/detachdisk.rb', __FILE__)
require File.expand_path('../../../azure_base/libraries/logger.rb', __FILE__)
require File.expand_path('../../../azure_base/libraries/utils.rb', __FILE__)
require File.expand_path('../../../azure_base/libraries/resource_group_manager.rb', __FILE__)

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

#determine which storage acct to use (prm or std)
size = node[:workorder][:payLoad][:RequiresComputes][0][:ciAttributes][:size]
storage_type = nil
if Utils.is_prm(size, true)
  storage_acct = 'storage_account_prm'
else
  storage_acct = 'storage_account_std'
end

Chef::Log.info("Choosing #{storage_acct}")
cloud_name = node[:workorder][:cloud][:ciName]
storage_service = node[:workorder][:services][:storage][cloud_name]
storage = storage_service["ciAttributes"]

rg_manager = AzureBase::ResourceGroupManager.new(node)

storage_account_name = node['workorder']['services']['storage'][cloud_name]['ciAttributes'][storage_acct]

instance_name = nil
if node.workorder.payLoad.has_key?("DependsOn")
 instance_name = node.workorder.payLoad.DependsOn[0]["ciAttributes"]["instance_name"]
 if instance_name != nil
   OOLog.info('instance_name:'+instance_name)
 end
end

storage_client = StorageManagementClient.new(rg_manager.creds)
storage_client.subscription_id = rg_manager.subscription

storage_account_keys= storage_client.storage_accounts.list_keys(storage.master_rg,storage[storage_acct]).value!

OOLog.info('  storage_account_keys : ' +   storage_account_keys.body.inspect)
key1 = storage_account_keys.body.key1
key2 = storage_account_keys.body.key2
dev_map = node.workorder.rfcCi.ciAttributes["device_map"]

dev_map.split(" ").each do |dev|
  dev_id = dev.split(":")[4]
  storage_account_name = dev.split(":")[1]
  component_name = dev.split(":")[2]
  dev_name = dev_id.split("/").last
  blobname = "#{storage[storage_acct]}-#{component_name}-datadisk-#{dev_name}.vhd"
  status=AzureStorage::AzureDatadisk.delete_disk(storage_account_name,key1,blobname,1)
  if status == "DiskUnderLease"
    AzureStorage::AzureDatadisk.detach_disk_from_vm(instance_name,rg_manager.subscription,rg_manager.rg_name,rg_manager.creds,dev_map.split(" "))
    AzureStorage::AzureDatadisk.delete_disk(storage_account_name,key1,blobname,1)
  end
end
