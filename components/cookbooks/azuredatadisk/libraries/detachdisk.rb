module AzureStorage
  class AzureDatadisk

    def self.get_credentials(tenant_id,client_id,client_secret)
      OOLog.info("tenant_id: #{tenant_id} client_id: #{client_id} client_secret: #{client_secret} ")
      begin
         # Create authentication objects
         token_provider = MsRestAzure::ApplicationTokenProvider.new(tenant_id,client_id,client_secret)
         if token_provider != nil
           credentials = MsRest::TokenCredentials.new(token_provider)
           credentials
         else
           raise e
         end
        rescue  MsRestAzure::AzureOperationError =>e
          OOLog.info("Error acquiring a token from azure")
      end
    end

    def self.delete_disk(storage_account_name,access_key,blobname)
      c=Azure::Core.config()
      c.storage_access_key = access_key
      c.storage_account_name = storage_account_name

      service = Azure::Blob::BlobService.new()

      container = "vhds"
      # Delete a Blob
      begin
        lease_time_left = service.break_lease(container, blobname)
        OOLog.info("Waiting for the lease time on #{blobname} to expire")
        if lease_time_left < 10
          sleep lease_time_left+10
        end
        delete_result = "success"
        retry_count = 20
        begin
          if retry_count > 0
            OOLog.info("Trying to delete the data disk page (page blob):#{blobname} ....")
            delete_result = service.delete_blob(container, blobname)
          end
          retry_count = retry_count-1
        end until delete_result == nil
        if delete_result !=nil && retry_count == 0
          OOLog.debug("Error in deleting the data disk (page blob):#{blobname}")
        end
      rescue Exception => e
        OOLog.debug(e.message)
      end
      OOLog.info("Successfully deleted the Datadisk(page blob):#{blobname}")
    end

    def self.detach_disk_from_vm(instance_name, subscription_id,rg_name,credentials,device_maps)
      client = Azure::ARM::Compute::ComputeManagementClient.new(credentials)
      client.subscription_id = subscription_id
      i=2
      vm = nil
      vm = get_vm_info(instance_name,client,rg_name)  
      device_maps.each do |dev_vol|
        slice_size = dev_vol.split(":")[3]
        dev_id = dev_vol.split(":")[4]
        storage_account_name = dev_vol.split(":")[1]
        component_name = dev_vol.split(":")[2]
        storage_account_rg_name = dev_vol.split(":")[0]
        dev_name = dev_id.split("/").last
        diskname = "#{component_name}-datadisk-#{dev_name}"
        #Detach a data disk
        flag = false
        (vm.properties.storage_profile.data_disks).each do |disk|        
          if disk.name == diskname  
            OOLog.info("deleting disk at lun:"+(disk.lun).to_s + " dev:#{dev_name} ")
            vm.properties.storage_profile.data_disks.delete_at(1)
          end  
         end 
         end
         if vm != nil
           OOLog.info("updating VM with these properties" + vm.inspect())
           update_vm_properties(instance_name,client,rg_name,vm)   
         end
    end
    
    #detach disk from the VM

    def self.update_vm_properties(instance_name,client,rg_name,vm)
      begin
        start_time = Time.now.to_i
        vm_promise = client.virtual_machines.create_or_update(rg_name, instance_name, vm)
        my_vm = vm_promise.value!
        end_time = Time.now.to_i
        duration = end_time - start_time
        OOLog.info("Storage Disk detached #{duration} seconds")
        OOLog.info("VM: #{my_vm.body.name} UPDATED!!!")
        return true
      rescue  MsRestAzure::AzureOperationError =>e
          OOLog.fatal(e.body)
      rescue Exception => ex
          OOLog.fatal(ex.message)
      end
    end

    # build the storage profile object to detach a datadisk
    def self.build_storage_profile(disk_no,component_name)
      data_disk2 = Azure::ARM::Compute::Models::DataDisk.new
      dev_name = dev_id.split("/").last
      data_disk2.name = "#{component_name}-datadisk-#{dev_name}"
      OOLog.info("data_disk:"+data_disk2.name)
      data_disk2.lun = disk_no-1
      OOLog.info("data_disk lun:"+data_disk2.lun.to_s)
      data_disk2
    end
    
      # Get the information about the VM
    def self.get_vm_info(instance_name,client,rg_name)
      promise = client.virtual_machines.get(rg_name, instance_name)
      result = promise.value!
      OOLog.info("vm info :"+result.body.inspect)
      return result.body
    end

  end
  end