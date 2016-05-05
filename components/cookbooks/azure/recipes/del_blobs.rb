require 'azure'

os_disk_blobname = (node['vhd_uri'].split("/").last)
OOLog.info("Deleting os_disk : #{os_disk_blobname}")
AzureStorage::AzureDatadisk.delete_disk(node['storage_account'],node['storage_key1'],os_disk_blobname,0)

data_disk_blobname = (node['datadisk_uri'].split("/").last)
OOLog.info("Deleting data_disk : #{data_disk_blobname}")
AzureStorage::AzureDatadisk.delete_disk(node['storage_account'],node['storage_key1'],data_disk_blobname,0)
