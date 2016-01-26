module AzureNetwork
  class NetworkInterfaceCard

    def initialize(credentials, subscription_id)
      @client = Azure::ARM::Network::NetworkResourceProviderClient.new(credentials)
      @client.subscription_id = subscription_id
    end

    def get(resource_group_name, nic_name)
      begin
        promise = @client.network_interfaces.get(resource_group_name, nic_name)
        response = promise.value!
        result = response.body
        return result
      rescue  MsRestAzure::AzureOperationError =>e
        Chef::Log.error("Error getting NIC '#{nic_name}'")
        Chef::Log.error("Error Response: #{e.response}")
        Chef::Log.error("Error Body: #{e.body}")
        return nil
      end
    end

    def create_update(location, rg_name, nic_name, net_interface_props)

      nic = NetworkInterface.new
      nic.location = location
      nic.properties = net_interface_props

      begin
        puts("Updating NIC '#{nic_name}' ")
        start_time = Time.now.to_i
        promise = @client.network_interfaces.create_or_update(rg_name, nic_name, nic)
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        puts("NIC '#{nic_name}' was updated in #{duration} seconds")
        return result
      rescue  MsRestAzure::AzureOperationError =>e
        Chef::Log.error("Error creating/updating NIC '#{nic_name}' ")
        Chef::Log.error("Error Response: #{e.response}")
        Chef::Log.error("Error Body: #{e.body}")
        return nil
      end

    end

  end
end
