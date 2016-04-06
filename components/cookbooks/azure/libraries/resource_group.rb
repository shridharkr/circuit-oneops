require 'azure_mgmt_resources'
require File.expand_path('../azure_utils.rb', __FILE__)
require File.expand_path('../../../azure_base/libraries/logger.rb', __FILE__)

::Chef::Recipe.send(:include, AzureCommon)
::Chef::Recipe.send(:include, Azure::ARM::Resources)
::Chef::Recipe.send(:include, Azure::ARM::Resources::Models)

# Module for Azure resource groups
module AzureResources
  # class to handle operations on the Azure Resource Group
  class ResourceGroup
    def initialize(compute_service)
      creds =
        AzureCommon::AzureUtils.get_credentials(compute_service['tenant_id'],
                                                compute_service['client_id'],
                                                compute_service['client_secret']
                                               )

      @client = Azure::ARM::Resources::ResourceManagementClient.new(creds)
      @client.subscription_id = compute_service['subscription']
    end

    # this method will create/update the resource group with the info passed in
    def add(rg_name, location)
      begin
        resource_group = ResourceGroup.new
        resource_group.location = location

        start_time = Time.now.to_i
        response =
          @client.resource_groups.create_or_update(rg_name,
                                                   resource_group).value!
        end_time = Time.now.to_i
        OOLog.info("Resource Group created in #{end_time - start_time} seconds")
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal(e.body.values[0]['message'])
      rescue => ex
        OOLog.fatal(ex.message)
      end
    end

    # This method will retrieve the resource group from azure.
    def get(rg_name)
      begin
        existance_promise = @client.resource_groups.check_existence(rg_name)
        response = existance_promise.value!
        result = response.body
        result
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal(e.body.values[0]['message'])
      rescue => ex
        OOLog.fatal(ex.message)
      end
    end

    # def delete
    #
    # end

  end
end
