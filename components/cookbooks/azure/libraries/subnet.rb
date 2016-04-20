require 'azure_mgmt_network'

module AzureNetwork

  class Subnet

    # Include SDK modules to ease access to network classes.
    include Azure::ARM::Network
    include Azure::ARM::Network::Models

    def initialize(credentials, subscription_id)
      @client = Azure::ARM::Network::NetworkResourceProviderClient.new(credentials)
      @client.subscription_id = subscription_id
    end

    def list(resource_group_name, vnet_name)
      begin
        puts("Getting all subnets from Resource Group '#{resource_group_name}'/vnet '#{vnet_name}'  ...")
        start_time = Time.now.to_i
        promise = @client.subnets.list(resource_group_name, vnet_name)
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

    def get(resource_group_name, vnet_name, subnet_name)
      begin
        puts("Getting subnet '#{subnet_name}' from Resource Group '#{resource_group_name}'/vnet '#{vnet_name}'  ...")
        start_time = Time.now.to_i
        promise = @client.subnets.get(resource_group_name, vnet_name, subnet_name)
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

  end

end