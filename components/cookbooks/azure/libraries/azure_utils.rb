

module AzureCommon
  class AzureUtils
    def self.get_credentials(tenant_id, client_id, client_secret)
      begin
        # Create authentication objects
        token_provider = MsRestAzure::ApplicationTokenProvider.new(tenant_id,client_id,client_secret)
        if token_provider != nil
          credentials = MsRest::TokenCredentials.new(token_provider)
          return credentials
        else
          raise "Could not retrieve azure credentials"
          exit 1
        end
      rescue  MsRestAzure::AzureOperationError =>e
        Chef::Log.error("Error acquiring a token from azure")
        raise e
      end
    end
  end
end