module AzureNetwork
  class AzureVirtualNetwork

    def initialize(credentials, subscription_id)
      @client = Azure::ARM::Network::NetworkResourceProviderClient.new(credentials)
      @client.subscription_id = subscription_id
    end

    def create_update_network(resource_group_name, network_name, virtual_network)
      begin

        promise = @client.virtual_networks.create_or_update(resource_group_name, network_name, virtual_network)
        result = promise.value!
        virtual_network_obj = result.body
        Chef::Log.info('Successfully created/updated network name: ' + network_name)
        return virtual_network_obj

      rescue MsRestAzure::AzureOperationError => e
        Chef::Log.error('***FAULT:FATAL=creating/updating ' + network_name + ' in resource group: ' + resource_group_name)
        Chef::Log.error('***FAULT:FATAL=' + e.body.to_s)
        exit 1
      end

    end

    def get_vnet(resource_group_name, network_name)
      begin
        promise = @client.virtual_networks.get(resource_group_name, network_name)
        response = promise.value!
        result = response.body
        return result
      rescue MsRestAzure::AzureOperationError => e
        Chef::Log.error('Network ' + network_name + ' not found')
        Chef::Log.error('Error: ' + e.body.to_s)
        return nil
      end
    end
  end
end




