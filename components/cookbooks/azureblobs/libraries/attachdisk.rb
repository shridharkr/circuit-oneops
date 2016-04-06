
module AzureStorage
  class AzureBlobs



    def self.attach_disk(instance_name, subscription_id,rg_name,credentials,device_maps )
      vols = Array.new
      dev_list = ""
      i = 2
      dev_id=""
      Chef::Log.info('Subscription id is: ' + subscription_id)
      client = Azure::ARM::Compute::ComputeManagementClient.new(credentials)
      client.subscription_id = subscription_id

      device_maps.each do |dev_vol|
        slice_size = dev_vol.split(":")[3]
        dev_id = dev_vol.split(":")[4]
        storage_account_name = dev_vol.split(":")[1]
        component_name = dev_vol.split(":")[2]
        Chef::Log.info("slice_size :#{slice_size}, dev_id: #{dev_id}")
        vm = get_vm_info(instance_name,client,rg_name)

        #Add a data disk
        flag = false
        (vm.properties.storage_profile.data_disks).each do |disk|
          if disk.lun == i-1
            flag = true
          end
        end
        if flag == true
          i = i+1
          next
        end
        vm.properties.storage_profile.data_disks.push(build_storage_profile(i,component_name,storage_account_name,slice_size,dev_id))
        # client.virtual_machines = vm
         attach_disk_to_vm(instance_name,client,rg_name,vm)
          Chef::Log.info("Adding #{dev_id} to the dev list")
          i = i+1
      end
      dev_id
    end

    #attach disk to the VM

    def self.attach_disk_to_vm(instance_name,client,rg_name,vm)
      begin

        start_time = Time.now.to_i
        vm_promise = client.virtual_machines.create_or_update(rg_name, instance_name, vm)
        my_vm = vm_promise.value!
        end_time = Time.now.to_i
        duration = end_time - start_time
        Chef::Log.info("Storage Disk attached #{duration} seconds")
        Chef::Log.info("VM: #{my_vm.body.name} UPDATED!!!")
        return true
      rescue  MsRestAzure::AzureOperationError =>e
        Chef::Log.error("Error attaching disk to azure VM")
        Chef::Log.debug("Error Body: #{e.body}")
        return false
      end
    end
    # Get the information about the VM

    def self.get_vm_info(instance_name,client,rg_name)

      promise = client.virtual_machines.get(rg_name, instance_name)
      result = promise.value!
      Chef::Log.info("vm info :"+result.body.inspect)
      return result.body
    end

    #Get storage account name to use

    def self.get_storage_account_name(vm)
      storage_account_name=((vm.properties.storage_profile.os_disk.vhd.uri).split(".")[0]).split("//")[1]
      Chef::Log.info("storage account to use:"+storage_account_name)
      storage_account_name
    end

    # build the storage profile object to add a new datadisk

    def self.build_storage_profile(disk_no,component_name,storage_account_name,slice_size,dev_id)
      data_disk2 = Azure::ARM::Compute::Models::DataDisk.new
      dev_name = dev_id.split("/").last
      data_disk2.name = "#{component_name}-datadisk-#{dev_name}"
      Chef::Log.info("data_disk:"+data_disk2.name)
      data_disk2.lun = disk_no-1
      Chef::Log.info("data_disk lun:"+data_disk2.lun.to_s)
      data_disk2.disk_size_gb = slice_size
      data_disk2.vhd = Azure::ARM::Compute::Models::VirtualHardDisk.new
      data_disk2.vhd.uri = "https://#{storage_account_name}.blob.core.windows.net/vhds/#{storage_account_name}-#{component_name}-datadisk-#{dev_name}.vhd"
      Chef::Log.info("data_disk uri:"+data_disk2.vhd.uri)
      data_disk2.caching = Azure::ARM::Compute::Models::CachingTypes::ReadWrite
      data_disk2.create_option = Azure::ARM::Compute::Models::DiskCreateOptionTypes::Empty
      data_disk2
    end

  end
end
