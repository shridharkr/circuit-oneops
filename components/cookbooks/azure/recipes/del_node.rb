require File.expand_path('../../libraries/utils.rb', __FILE__)
require File.expand_path('../../libraries/azure_utils.rb', __FILE__)
require 'azure_mgmt_compute'
require 'azure_mgmt_network'
require 'azure_mgmt_storage'

::Chef::Recipe.send(:include, Utils)
::Chef::Recipe.send(:include, Azure::ARM::Compute)
::Chef::Recipe.send(:include, Azure::ARM::Compute::Models)
::Chef::Recipe.send(:include, Azure::ARM::Network)
::Chef::Recipe.send(:include, Azure::ARM::Network::Models)
::Chef::Recipe.send(:include, Azure::ARM::Storage)
::Chef::Recipe.send(:include, Azure::ARM::Storage::Models)

#set the proxy if it exists as a cloud var
AzureCommon::AzureUtils.set_proxy(node.workorder.payLoad.OO_CLOUD_VARS)

#Get the vm object from azure given a resource group and compute name
def get_vm(client, resource_group_name, vm_name)
  begin
      puts("Getting VM #{vm_name}")
      start_time = Time.now.to_i
      promise = client.virtual_machines.get(resource_group_name, vm_name)
      result = promise.value!
      end_time = Time.now.to_i

      duration = end_time - start_time

      puts("VM fetched in #{duration} seconds")

      return result.body
    rescue  MsRestAzure::AzureOperationError =>e
      puts 'Error fetching VM'
      puts("Error Response: #{e.response}")
      puts("Error Body: #{e.body}")
      return nil
    end
end

# delete the NIC from the platform specific resource group
def delete_nic(credentials, subscription_id, resource_group_name, nic_name)
  begin
    start_time = Time.now.to_i
    networkclient = NetworkResourceProviderClient.new(node['azureCredentials'])
    networkclient.subscription_id = subscription_id
    promise = networkclient.network_interfaces.delete(resource_group_name, nic_name)
    result = promise.value!
    end_time = Time.now.to_i
    duration = end_time - start_time
    Chef::Log.info("Deleting NIC '#{nic_name}' in #{duration} seconds")
  rescue MsRestAzure::AzureOperationError => e
    puts("***FAULT:FATAL deleting NIC, resource group: '#{resource_group_name}', NIC name: '#{nic_name}'")
    Chef::Log.error("Exception is=#{e.message}")
    e = Exception.new("no backtrace")
    e.set_backtrace("")
    raise e
  end
end

#Delete public ip assocaited with the VM
def delete_publicip(credentials,subscription_id,resource_group_name, public_ip_name)
  begin
    start_time = Time.now.to_i
    networkclient = NetworkResourceProviderClient.new(node['azureCredentials'])
    networkclient.subscription_id = compute_service['subscription']
    promise = networkclient.public_ip_addresses.delete(resource_group_name, public_ip_name)
    details = promise.value!
    end_time = Time.now.to_i
    duration = end_time - start_time
    Chef::Log.info("Deleting public ip '#{public_ip_name}' in #{duration} seconds")
 end
end

#Delete both Page blob(vhd) and Block Blob from the storage account
#associated with the vm
def delete_vm_storage(credentials, subscription_id, resource_group_name,storage_account)
  begin
    storage_client = StorageManagementClient.new(credentials)
    storage_client.subscription_id = subscription_id

    storage_account_keys= storage_client.storage_accounts.list_keys(resource_group_name,storage_account).value!
    Chef::Log.info('  storage_account_keys : ' +   storage_account_keys.body.inspect)
    node.set['storage_key1'] = storage_account_keys.body.key1
    node.set['storage_key2'] = storage_account_keys.body.key2
    Chef::Log.info('vhd_uri : ' + node['vhd_uri'] )

    #Get the full name of the block blob associated with the deleted vm.
    include_recipe "azure::get_blob_list"
    num_blob_names = node['blobs'].xpath("/EnumerationResults/Blobs/Blob/Name")
    Chef::Log.debug("Total Number of blobs: #{num_blob_names.count}")
    extract_text = ''
    num_blob_names.each do |blob_elem|
      Chef::Log.debug ("ELEMENT: #{blob_elem}")
      Chef::Log.debug ("INNER TEXT: #{blob_elem.text}")
      if ((blob_elem.text).split(".").first == node['server_name']) and /status/.match(blob_elem.text)
        Chef::Log.debug ("Found the block blob associated with the deleted VM: #{blob_elem.text}")
        extract_text = blob_elem.text
      end
    end
    @arr = extract_text.split('.')
      Chef::Log.debug('id from azure : ' + @arr[1])
    node.set["block_blob_uri"]="https://"+storage_account+".blob.core.windows.net/vhds/"+node['server_name']+"."+@arr[1]+".status"
    Chef::Log.info('block blob : ' + node["block_blob_uri"] )

    #Delete both page(vhd) blob and block blob
    include_recipe "azure::del_blobs"
  end
end

cloud_name = node['workorder']['cloud']['ciName']
Chef::Log.info('cloud_name is: ' + cloud_name)
compute_service = node['workorder']['services']['compute'][cloud_name]['ciAttributes']

# handle token and credentials
subscription_id = compute_service['subscription']
Chef::Log.info('Subscription id is: ' + subscription_id)

# invoke recipe to get credentials
include_recipe "azure::get_credentials"

credentials = node['azureCredentials']

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'

server_name = node['server_name']
cloud_name = node['workorder']['cloud']['ciName']
Chef::Log.info("Cloud Name: #{cloud_name}")
compute_service = node['workorder']['services']['compute'][cloud_name]['ciAttributes']
express_route_enabled = compute_service['express_route_enabled']
if express_route_enabled == 'true'
  ip_type = 'private'
else
  ip_type = 'public'
end
# delete the VM
begin
  start_time = Time.now.to_i
  client = ComputeManagementClient.new(credentials)
  client.subscription_id = subscription_id

  vm = get_vm(client, node['platform-resource-group'], server_name)

  if vm.nil?
    Chef::Log.info("VM '#{server_name}' was not found. Nothing to delete. ")
  else
    #retrive the vhd name from the VM properties and use it to delete the associated VHD in the later step.
    vhd_uri = vm.properties.storage_profile.os_disk.vhd.uri
    storage_account  = (vhd_uri.split(".").first).split("//").last
    node.set["storage_account"] = storage_account
    node.set["vhd_uri"]=vhd_uri
    Chef::Log.info(vm.properties.inspect)
    node.set["datadisk_uri"] = vm.properties.storage_profile.data_disks[0].vhd.uri
    nameutil = Utils::NameUtils.new()
    ci_name = node['workorder']['rfcCi']['ciId']
    Chef::Log.info("Deleting Azure VM: '#{server_name}'")
    #delete the VM from the platform resource group
    result = client.virtual_machines.delete(node['platform-resource-group'], server_name).value!
    Chef::Log.info("Delete VM response is: #{result.inspect}")
    if ip_type == 'public'
      public_ip_name = nameutil.get_component_name("publicip",ci_name)
      delete_publicip(credentials, subscription_id, node['platform-resource-group'],public_ip_name)
    end
    # delete the NIC. A NIC is created with each VM, so we will delete the NIC when we delete the VM
    nic_name = nameutil.get_component_name("nic",ci_name)
    if ip_type == 'public'
      delete_nic(credentials, subscription_id, node['platform-resource-group'], nic_name)
    elsif ip_type == 'private'
      delete_nic(credentials, subscription_id, compute_service['resource_group'], nic_name)
    end
    #delete the blobs
    #Delete both Page blob(vhd) and Block Blob from the storage account
    delete_vm_storage(credentials, subscription_id, node['platform-resource-group'],storage_account)
  end
rescue MsRestAzure::AzureOperationError => e
   puts("***FAULT:FATAL deleting VM, resource group: #{node['platform-resource-group']}, VM name: #{node['server_name']}. Exception is=#{e.message}")
   Chef::Log.error("***FAULT:Error deleting VM. Resource Group: #{node['platform-resource-group']} , VM name: #{node['server_name']}")
   Chef::Log.error("***FAULT:Error deleting VM: #{e.body}")
   Chef::Log.error("Error body: #{e.body}")
   e = Exception.new("no backtrace")
   e.set_backtrace("")
   raise e
 ensure
   end_time = Time.now.to_i
   duration = end_time - start_time
   Chef::Log.info("Deleting VM took #{duration} seconds")
end

Chef::Log.info("Exiting azure delete compute")
