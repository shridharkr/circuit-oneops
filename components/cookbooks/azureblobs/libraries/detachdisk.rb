
module AzureStorage
  class AzureBlobs



    def self.get_credentials(tenant_id,client_id,client_secret)
      Chef::Log.info("tenant_id: #{tenant_id} client_id: #{client_id} client_secret: #{client_secret} ")
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
          Chef::Log.error("Error acquiring a token from azure")
      end
    end

    def self.delete_blob(storage_account,access_key,blobname)
       Azure.storage_account_name = storage_account
       Azure.storage_access_key = access_key
       blobs = Azure.blobs
       container = "vhds"
       # Delete a Blob
       begin
         lease_time_left = blobs.break_lease(container, blobname)
         Chef::Log.info("Waiting for the lease time #{lease_time_left} to expire")
         if lease_time_left < 10
            sleep lease_time_left+10
         end
         blobs.delete_blob(container, blobname)
         Chef::Log.info("Successfully deleted the blob")
         rescue => e
         Chef::Log.info("Error in deleting the blob"+e.message)
      end

    end

  end
  end