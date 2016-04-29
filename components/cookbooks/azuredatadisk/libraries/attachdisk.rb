
module AzureStorage
  class AzureDatadisk

    def self.attach_disk(instance_name, subscription_id,rg_name,credentials,device_maps )
      vols = Array.new
      dev_list = ""
      i = 2
      dev_id=""
      OOLog.info('Subscription id is: ' + subscription_id)
      client = Azure::ARM::Compute::ComputeManagementClient.new(credentials)
      client.subscription_id = subscription_id
      storage_client = Azure::ARM::Storage::StorageManagementClient.new(credentials)
      storage_client.subscription_id = subscription_id
      
      device_maps.each do |dev_vol|
        slice_size = dev_vol.split(":")[3]
        dev_id = dev_vol.split(":")[4]
        storage_account_name = dev_vol.split(":")[1]
        component_name = dev_vol.split(":")[2]
        storage_account_rg_name = dev_vol.split(":")[0]
        OOLog.info("slice_size :#{slice_size}, dev_id: #{dev_id}")
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
        access_key = get_storage_access_key(storage_account_name,storage_account_rg_name,storage_client)
        vm.properties.storage_profile.data_disks.push(build_storage_profile(i,component_name,storage_account_name,slice_size,dev_id,access_key))
        attach_disk_to_vm(instance_name,client,rg_name,vm)
        OOLog.info("Adding #{dev_id} to the dev list")
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
        OOLog.info("Storage Disk attached #{duration} seconds")
        OOLog.info("VM: #{my_vm.body.name} UPDATED!!!")
        return true
      rescue  MsRestAzure::AzureOperationError =>e
          OOLog.fatal(e.body)
      rescue Exception => ex
          OOLog.fatal(ex.message)
      end
    end
    
    # Get the information about the VM
    def self.get_vm_info(instance_name,client,rg_name)
      promise = client.virtual_machines.get(rg_name, instance_name)
      result = promise.value!
      OOLog.info("vm info :"+result.body.inspect)
      return result.body
    end

    #Get storage account name to use

    def self.get_storage_account_name(vm)
      storage_account_name=((vm.properties.storage_profile.os_disk.vhd.uri).split(".")[0]).split("//")[1]
      OOLog.info("storage account to use:"+storage_account_name)
      storage_account_name
    end

    # build the storage profile object to add a new datadisk
    def self.build_storage_profile(disk_no,component_name,storage_account_name,slice_size,dev_id,access_key)
      data_disk2 = Azure::ARM::Compute::Models::DataDisk.new
      dev_name = dev_id.split("/").last
      data_disk2.name = "#{component_name}-datadisk-#{dev_name}"
      OOLog.info("data_disk:"+data_disk2.name)
      data_disk2.lun = disk_no-1
      OOLog.info("data_disk lun:"+data_disk2.lun.to_s)
      data_disk2.disk_size_gb = slice_size
      data_disk2.vhd = Azure::ARM::Compute::Models::VirtualHardDisk.new
      data_disk2.vhd.uri = "https://#{storage_account_name}.blob.core.windows.net/vhds/#{storage_account_name}-#{component_name}-datadisk-#{dev_name}.vhd"
      OOLog.info("data_disk uri:"+data_disk2.vhd.uri)
      data_disk2.caching = Azure::ARM::Compute::Models::CachingTypes::ReadWrite
      blob_name = "#{storage_account_name}-#{component_name}-datadisk-#{dev_name}.vhd"
      is_new_disk_or_old = check_blob_exist(storage_account_name,blob_name,access_key)
      if is_new_disk_or_old == true
        data_disk2.create_option = Azure::ARM::Compute::Models::DiskCreateOptionTypes::Attach
      else
        data_disk2.create_option = Azure::ARM::Compute::Models::DiskCreateOptionTypes::Empty
      end
      data_disk2
    end

    def self.check_blob_exist(storage_account_name,blobname,access_key)
      c=Azure::Core.config()
      c.storage_access_key = access_key
      c.storage_account_name = storage_account_name
      service = Azure::Blob::BlobService.new()
      container = "vhds"
      begin
        blob_prop = service.get_blob_properties(container,blobname)
        if blob_prop != nil
          OOLog.info("disk exists")
          return true
        end
      rescue Exception => e
        OOLog.debug(e.message)
        return false
      end
    end

    def self.get_storage_access_key(storage_account_name,rg_name,storage_client)
      storage_account_keys= storage_client.storage_accounts.list_keys(rg_name,storage_account_name).value!
      OOLog.info('  storage_account_keys : ' +   storage_account_keys.body.inspect)
      key1 = storage_account_keys.body.key1
      key2 = storage_account_keys.body.key2
      return key2
    end
  end
end
