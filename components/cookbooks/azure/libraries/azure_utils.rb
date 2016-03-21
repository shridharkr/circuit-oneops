# Common class for common methods, like get_credentials.

module AzureCommon
  class AzureUtils
    def self.get_credentials(tenant_id, client_id, client_secret)
      begin
        # Create authentication objects
        token_provider = MsRestAzure::ApplicationTokenProvider.new(tenant_id,client_id,client_secret)
        if token_provider != nil
          credentials = MsRest::TokenCredentials.new(token_provider)
          credentials
        else
          e = Exception.new('Could not retrieve azure credentials')
          raise e
        end
      rescue  MsRestAzure::AzureOperationError => e
        Chef::Log.error('Error acquiring a token from azure')
        raise e
      end
    end
  end
end