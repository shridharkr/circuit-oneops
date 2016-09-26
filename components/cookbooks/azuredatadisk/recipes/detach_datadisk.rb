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
tenant_id = node['workorder']['services']['compute'][cloud_name]['ciAttributes']['tenant_id']
client_id = node['workorder']['services']['compute'][cloud_name]['ciAttributes']['client_id']
client_secret = node['workorder']['services']['compute'][cloud_name]['ciAttributes']['client_secret']
subscription = node['workorder']['services']['compute'][cloud_name]['ciAttributes']['subscription']

instance_name = nil
if node.workorder.payLoad.has_key?("ManagedVia")
 instance_name = node.workorder.payLoad.ManagedVia[0]["ciAttributes"]["instance_name"]
 if instance_name != nil
   OOLog.info('instance_name:'+instance_name)
 end
end

node.set["azureCredentials"] = AzureStorage::AzureDatadisk.get_credentials(tenant_id,client_id,client_secret)

storage = nil
node.workorder.payLoad.DependsOn.each do |dep|
  if dep["ciClassName"] =~ /Storage/
    storage = dep
    break
  end
end

rgname=nil
storage_account_name=nil

storage.ciAttributes.device_map.split(" ").each do |dev|
  rgname = dev.split(":")[0]
  storage_account_name = dev.split(":")[1]
end

storage_client = StorageManagementClient.new(node.azureCredentials)
storage_client.subscription_id = subscription

storage_account_keys= storage_client.storage_accounts.list_keys(rgname,storage_account_name).value!

OOLog.info('  storage_account_keys : ' +   storage_account_keys.body.inspect)
key1 = storage_account_keys.body.key1
key2 = storage_account_keys.body.key2

OOLog.info("storage_account_name : #{storage_account_name}, rgname : #{rgname}")

if instance_name != nil && rgname != nil && storage_account_name != nil
 OOLog.info('Detaching disk from VM')
 rgname = node['platform-resource-group']
 device_maps = storage.ciAttributes["device_map"].split(" ")
 AzureStorage::AzureDatadisk.detach_disk_from_vm(instance_name,subscription,rgname,node['azureCredentials'],device_maps)
end
