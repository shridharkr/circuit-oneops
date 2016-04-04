
require 'azure_mgmt_compute'
require 'azure_mgmt_storage'
require File.expand_path('../../../azure/libraries/azure_utils.rb', __FILE__)
# invoke recipe to get credentials
include_recipe "azure::get_credentials"


credentials = node['azureCredentials']

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'

cloud_vars = node.workorder.payLoad.OO_CLOUD_VARS

cloud_vars.each do |var|
  if var[:ciName] == 'apiproxy'
    ENV['http_proxy'] = var[:ciAttributes][:value]
    ENV['https_proxy'] = var[:ciAttributes][:value]
  end
end

Chef::Log.info("device maps "+node[:device_maps].inspect())
vols = Array.new
dev_list = ""
i = 2

  node[:device_maps].each do |dev_vol|
    slice_size = dev_vol.split(":")[0]
    dev_id = dev_vol.split(":")[1]
    #dev_id = "/dev/sdd" + i.to_s()
    Chef::Log.info("slice_size :#{slice_size}, dev_id: #{dev_id}")

    instance_name = node.workorder.payLoad.ManagedVia[0]["ciAttributes"]["instance_name"]
    cloud_name = node['workorder']['cloud']['ciName']
    Chef::Log.info('cloud_name is: ' + cloud_name)
    compute_service = node['workorder']['services']['compute'][cloud_name]['ciAttributes']

    # handle token and credentials
    subscription_id = compute_service['subscription']
    Chef::Log.info('Subscription id is: ' + subscription_id)
    client = Azure::ARM::Compute::ComputeManagementClient.new(credentials)
    client.subscription_id = subscription_id
    promise = client.virtual_machines.get(node['platform-resource-group'], instance_name)
    result = promise.value!
    Chef::Log.info("vm info :"+result.body.inspect)
    vm = result.body
    storage_account_name = ((vm.properties.storage_profile.os_disk.vhd.uri).split(".")[0]).split("//")[1]
    Chef::Log.info("storage account to use:"+storage_account_name)
    #Add a data disk
    flag = false
    (vm.properties.storage_profile.data_disks).each do |disk|
      if disk.lun == i-1
        flag = true
      end
    end
    if flag == true
      vols.push dev_id
      #node.set["raid_device"] = dev_id
      node.set["device"] = dev_id
      dev_list += dev_id+" "
      i = i+1
      next
    end
    data_disk2 = Azure::ARM::Compute::Models::DataDisk.new
    data_disk2.name = "#{instance_name}-datadisk#{i.to_s}"
    Chef::Log.info("data_disk:"+data_disk2.name)
    data_disk2.lun = i-1
    Chef::Log.info("data_disk lun:"+data_disk2.lun.to_s)
    data_disk2.disk_size_gb = slice_size
    data_disk2.vhd = Azure::ARM::Compute::Models::VirtualHardDisk.new
    data_disk2.vhd.uri = "https://#{storage_account_name}.blob.core.windows.net/vhds/#{storage_account_name}-#{instance_name}-data#{i.to_s}.vhd"
    Chef::Log.info("data_disk uri:"+data_disk2.vhd.uri)
    data_disk2.caching = Azure::ARM::Compute::Models::CachingTypes::ReadWrite
    data_disk2.create_option = Azure::ARM::Compute::Models::DiskCreateOptionTypes::Empty

    vm.properties.storage_profile.data_disks.push(data_disk2)
    # client.virtual_machines = vm
    start_time = Time.now.to_i
    vm_promise = client.virtual_machines.create_or_update(node['platform-resource-group'], instance_name, vm)
    my_vm = vm_promise.value!
    end_time = Time.now.to_i
    duration = end_time - start_time
    Chef::Log.info("Storage Disk attached #{duration} seconds")
    Chef::Log.info("VM: #{my_vm.body.name} UPDATED!!!")
    Chef::Log.info("Adding #{dev_id} to the dev list")
    vols.push dev_id
    node.set["raid_device"] = dev_id
    node.set["device"] = dev_id
    dev_list += dev_id+" "
    i = i+1
  end
