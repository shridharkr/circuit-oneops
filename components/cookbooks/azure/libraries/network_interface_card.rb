module AzureNetwork

  class NetworkInterfaceCard

    def initialize(credentials, subscription_id)
      @client = Azure::ARM::Network::NetworkResourceProviderClient.new(credentials)
      @client.subscription_id = subscription_id
    end

    def get(resource_group_name, nic_name)
      begin
        puts("Fetching NIC '#{nic_name}' ")
        start_time = Time.now.to_i
        promise = @client.network_interfaces.get(resource_group_name, nic_name)
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        puts("operation took #{duration} seconds")
        return result
      rescue  MsRestAzure::AzureOperationError =>e
        puts("Error getting NIC '#{nic_name}'")
        puts("Error Response: #{e.response}")
        puts("Error Body: #{e.body}")
        return nil
      end
    end

    def create_update(location, resource_group_name, nic_name, nic_props)
      nic = Azure::ARM::Network::Models::NetworkInterface.new
      nic.location = location
      nic.properties = nic_props

      begin
        puts("Updating NIC '#{nic_name}' in '#{resource_group_name}' ")
        start_time = Time.now.to_i
        promise = @client.network_interfaces.create_or_update(resource_group_name, nic_name, nic)
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        puts("operation took #{duration} seconds")
        return result
      rescue  MsRestAzure::AzureOperationError =>e
        puts("Error creating/updating NIC '#{nic_name}' ")
        puts("Error Response: #{e.response}")
        puts("Error Body: #{e.body}")
        return nil
      end

    end

  end
end
