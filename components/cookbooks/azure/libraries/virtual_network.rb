module AzureNetwork
  class AzureVirtualNetwork

    def initialize(credentials, subscription_id)
      @client = Azure::ARM::Network::NetworkResourceProviderClient.new(credentials)
      @client.subscription_id = subscription_id
    end

    def define_subnet_objects(network_name, subnet_address_list)
      sub_nets = Array.new
      for i in 0..subnet_address_list.length-1
        Chef::Log.info('subnet_address_list[' + i.to_s + ']: ' + subnet_address_list[i].strip)
        subnet_properties = SubnetPropertiesFormat.new
        subnet_properties.address_prefix = subnet_address_list[i].strip

        subnet = Subnet.new
        subnet.name = 'subnet_' + i.to_s + '_' + network_name
        subnet.properties = subnet_properties
        sub_nets.push(subnet)
        Chef::Log.info('Subnet name is: ' + subnet.name)
      end

      return sub_nets
    end

    def define_network_object(resource_group_name,location, network_name, network_address, dns_list, subnet_address_list)
      begin
        Chef::Log.info('network_address: ' + network_address)
        address_space = AddressSpace.new
        address_space.address_prefixes = [network_address]

        ns_list = Array.new
        for i in 0..dns_list.length-1
          Chef::Log.info('dns address[' + i.to_s + ']: ' + dns_list[i].strip)
          ns_list.push(dns_list[i].strip)
        end
        dhcp_options = DhcpOptions.new
        if ns_list != nil
          dhcp_options.dns_servers = ns_list
        end

        sub_nets = define_subnet_objects(network_name, subnet_address_list)

        virtual_network_properties = VirtualNetworkPropertiesFormat.new
        virtual_network_properties.address_space = address_space
        virtual_network_properties.dhcp_options = dhcp_options
        virtual_network_properties.subnets = sub_nets

        virtual_network = VirtualNetwork.new
        virtual_network.location = location
        virtual_network.properties = virtual_network_properties
        promise = @client.virtual_networks.create_or_update(resource_group_name, network_name, virtual_network)
        result = promise.value!
        virtual_network_obj = result.body

        return virtual_network_obj

      rescue MsRestAzure::AzureOperationError => e
        Chef::Log.error("Error creating Virtual Network '#{network_name}' ")
        return nil
      end

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




