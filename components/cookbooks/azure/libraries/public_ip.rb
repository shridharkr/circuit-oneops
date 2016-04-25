require 'azure_mgmt_network'

::Chef::Recipe.send(:include, Azure::ARM::Network)
::Chef::Recipe.send(:include, Azure::ARM::Network::Models)

module AzureNetwork

  # this class should contain methods to manipulate public ip address within Azure.
  class PublicIp

    def initialize(credentials, subscription_id)
      @client = Azure::ARM::Network::NetworkResourceProviderClient.new(credentials)
      @client.subscription_id = subscription_id
    end

    # this fuction gets the public ip from azure for the given resource group and pip name
    def get(resource_group_name, public_ip_name)
      begin
        puts("Fetching public IP '#{public_ip_name}' from '#{resource_group_name}' ")
        start_time = Time.now.to_i
        promise = @client.public_ip_addresses.get(resource_group_name, public_ip_name)
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        puts("operation took #{duration} seconds")
        return result
      rescue  MsRestAzure::AzureOperationError =>e
        puts("Exception trying to get public ip #{public_ip_name} from resource group: #{resource_group_name}")
        puts("Error Response: #{e.response}")
        puts("Error Body: #{e.body}")
        raise e
      end
    end

    def delete(resource_group_name, public_ip_name)
      begin
        puts("Deleting public IP '#{public_ip_name}' from '#{resource_group_name}' ")
        start_time = Time.now.to_i
        promise = @client.public_ip_addresses.delete(resource_group_name, public_ip_name)
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        puts("operation took #{duration} seconds")
        return result
      rescue  MsRestAzure::AzureOperationError => e
        puts("Error deleting PublicIP '#{public_ip_name}' in ResourceGroup '#{resource_group_name}'")
        puts("Error Response: #{e.response}")
        puts("Error Body: #{e.body}")
        raise e
      end
    end

    # this function creates or updates the public ip address
    # it expects the resource group, name of the pip and public ip object to already be created.
    def create_update(location, resource_group_name, public_ip_name, public_ip_props)
      begin
        public_ip = Azure::ARM::Network::Models::PublicIpAddress.new
        public_ip.location = location
        public_ip.properties = public_ip_props

        puts("Creating/Updating public IP '#{public_ip_name}' from '#{resource_group_name}' ")
        start_time = Time.now.to_i
        promise = @client.public_ip_addresses.create_or_update(resource_group_name, public_ip_name, public_ip)
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        puts("operation took #{duration} seconds")
        return result
      rescue MsRestAzure::AzureOperationError => e
        puts("Error creating/updating public ip '#{public_ip_name}'")
        puts("Error Response: #{e.response}")
        puts("Error Body: #{e.body}")
        raise e
      end
    end

    # this fuction checks whether the public ip belongs to the given resource group 
    def check_existence_publicip(resource_group_name, public_ip_name)
      begin
        puts("Checking existance of public IP '#{public_ip_name}' in '#{resource_group_name}' ")
        start_time = Time.now.to_i
        promise = @client.public_ip_addresses.get(resource_group_name, public_ip_name)
        response = promise.value!
        # result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        puts("operation took #{duration} seconds")
        return true
      rescue  MsRestAzure::AzureOperationError => e
        puts("Error checking existance of IP #{public_ip_name}")
        puts("Error: #{e.body}")
        error_response = e.body["error"]
        puts("Error Response code: #{error_response["code"]}")
        if(error_response["code"] == "ResourceNotFound")
          return false
        else
          return true
        end
      end
    end

  end
end
