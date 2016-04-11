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
          OOLog.error("Error acquiring a token from azure")
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
        OOLog.info("Waiting for the lease time #{lease_time_left} on #{blobname} to expire")
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
          OOLog.error("Error in deleting the data disk (page blob):#{blobname}")
        end
      rescue Exception => e
        OOLog.fatal(e.message)
      end
      OOLog.info("Successfully deleted the Datadisk(page blob):#{blobname}")
    end

  end
  end