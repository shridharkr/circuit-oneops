require 'azure_mgmt_network'
require 'azure_mgmt_compute'

module AzureNetwork

  class VirtualNetwork

    # Include SDK modules to ease access to network classes.
    include Azure::ARM::Network
    include Azure::ARM::Network::Models

    def initialize(credentials, subscription_id)
      @client = Azure::ARM::Network::NetworkResourceProviderClient.new(credentials)
      @client.subscription_id = subscription_id
    end

    def get_vnet(resource_group_name, vnet_name)
      begin
        puts("Getting Virtual Network '#{vnet_name}' ...")
        start_time = Time.now.to_i
        promise = @client.virtual_networks.get(resource_group_name, vnet_name)
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time

        puts("operation took #{duration} seconds")

        return result
      rescue  MsRestAzure::AzureOperationError =>e
        puts 'Error creating Virtual Network'
        puts("Error Response: #{e.response}")
        puts("Error Body: #{e.body}")
      end
    end

    def get_vnets(resource_group_name)
      begin
        puts("Getting vnets from Resource Group '#{resource_group_name}' ...")
        start_time = Time.now.to_i
        promise = @client.virtual_networks.list(resource_group_name)
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time

        puts("operation took #{duration} seconds")

        return result

      rescue  MsRestAzure::AzureOperationError =>e
        puts 'Error creating Virtual Network'
        puts("Error Response: #{e.response}")
        puts("Error Body: #{e.body}")
      end
    end

    def get_subscription_vnets
      begin

        puts("Getting subscription vnets ...")
        start_time = Time.now.to_i
        promise = @client.virtual_networks.list_all()
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time

        puts("operation took #{duration} seconds")

        return result

      rescue  MsRestAzure::AzureOperationError =>e
        puts 'Error creating Virtual Network'
        puts("Error Response: #{e.response}")
        puts("Error Body: #{e.body}")
      end
    end

  end  # end of class

end