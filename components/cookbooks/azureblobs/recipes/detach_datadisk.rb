require 'azure_mgmt_compute'
require 'azure_mgmt_network'
require 'azure_mgmt_storage'
require 'time'
require 'uri'
require 'openssl'
require 'base64'
require 'net/https'
require 'net/http'
require 'rest_client'
require File.expand_path('../../../azure/libraries/azure_utils.rb', __FILE__)
require File.expand_path('../../libraries/detachdisk.rb', __FILE__)


::Chef::Recipe.send(:include, Azure::ARM::Compute)
::Chef::Recipe.send(:include, Azure::ARM::Compute::Models)
::Chef::Recipe.send(:include, Azure::ARM::Network)
::Chef::Recipe.send(:include, Azure::ARM::Network::Models)
::Chef::Recipe.send(:include, Azure::ARM::Storage)
::Chef::Recipe.send(:include, Azure::ARM::Storage::Models)

cloud_name = node['workorder']['cloud']['ciName']
tenant_id = node['workorder']['services']['storage'][cloud_name]['ciAttributes']['tenant_id']
client_id = node['workorder']['services']['storage'][cloud_name]['ciAttributes']['client_id']
client_secret = node['workorder']['services']['storage'][cloud_name]['ciAttributes']['client_secret']
subscription = node['workorder']['services']['storage'][cloud_name]['ciAttributes']['subscription']
storage_account_name = node['workorder']['services']['storage'][cloud_name]['ciAttributes']['storage_account']

 node.set["azureCredentials"] = AzureStorage::AzureBlobs.get_credentials(tenant_id,client_id,client_secret)

cloud_name = node[:workorder][:cloud][:ciName]
storage_service = node[:workorder][:services][:storage][cloud_name]
storage = storage_service["ciAttributes"]

storage_client = StorageManagementClient.new(node.azureCredentials)
storage_client.subscription_id = subscription

storage_account_keys= storage_client.storage_accounts.list_keys(storage.master_rg,storage.storage_account).value!
Chef::Log.info('  storage_account_keys : ' +   storage_account_keys.body.inspect)
key1 = storage_account_keys.body.key1
key2 = storage_account_keys.body.key2
dev_map = node.workorder.rfcCi.ciAttributes["device_map"]
dev_map.split(" ").each do |dev|
  slice_size = dev.split(":")[3]
  dev_id = dev.split(":")[4]
  storage_account_name = dev.split(":")[1]
  component_name = dev.split(":")[2]
  dev_name = dev_id.split("/").last
  blobname = "#{storage.storage_account}-#{component_name}-datadisk-#{dev_name}.vhd"

  AzureStorage::AzureBlobs.delete_blob(storage_account_name,key1,blobname)
end

