# Module for Azure resource groups
module AzureResources
  # class to handle operations on the Azure Resource Group
  class ResourceGroup

    def initialize(compute_service)
      creds = AzureCommon::AzureUtils.get_credentials(compute_service['tenant_id'], compute_service['client_id'], compute_service['client_secret'])

      @client = Azure::ARM::Compute::ComputeManagementClient.new(creds)
      @client.subscription_id = compute_service['subscription']
    end


  end
end
