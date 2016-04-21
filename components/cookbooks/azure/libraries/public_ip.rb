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
        promise = @client.public_ip_addresses.get(resource_group_name, public_ip_name)
        response = promise.value!
        result = response.body
        return result
      rescue  MsRestAzure::AzureOperationError =>e
        msg = "Exception trying to get public ip #{public_ip_name} from resource group: #{resource_group_name}"
        puts "***FAULT:FATAL=#{msg}"
        Chef::Log.error("Azure::PublicIp - Exception is: #{e.body}")
        e = Exception.new('no backtrace')
        e.set_backtrace('')
        raise e
      rescue Exception => e
        msg = "Exception trying to get public ip #{public_ip_name} from resource group: #{resource_group_name}"
        Chef::Log.error("Azure::PublicIp -#{msg}")
        puts "***FAULT:FATAL="+e.body.to_s
        Chef::Log.error("Azure::PublicIp - Exception is: #{e.message}")
        e = Exception.new('no backtrace')
        e.set_backtrace('')
        raise e
      end
    end

    def delete(resource_group_name, public_ip_name)
      begin
        promise = @client.public_ip_addresses.delete(resource_group_name, public_ip_name)
        response = promise.value!
        result = response.body
        return result
      rescue  MsRestAzure::AzureOperationError =>e
        msg = "Error deleting PublicIP '#{public_ip_name}' in ResourceGroup '#{resource_group_name}'"
        puts "***FAULT:FATAL=#{msg}"
        Chef::Log.error("Azure::PublicIp - Error Response: #{e.response}")
        Chef::Log.error("Azure::PublicIp - Error Body: #{e.body}")
        exit 1
      end
    end

    # this function creates or updates the public ip address
    # it expects the resource group, name of the pip and public ip object to already be created.
    def create_update(resource_group_name, public_ip_name, public_ip_address)
      begin
        promise = @client.public_ip_addresses.create_or_update(resource_group_name, public_ip_name, public_ip_address)
        response = promise.value!
        result = response.body
        return result
      rescue MsRestAzure::AzureOperationError => ex
        msg = "Exception trying to create/update public ip #{public_ip_address.name} from resource group: #{resource_group_name}"
        Chef::Log.error("Azure::PublicIp -#{msg}")
        puts "***FAULT:FATAL="+ex.body.to_s
        Chef::Log.error("Azure::PublicIp - Exception is: #{ex.body}")
        e = Exception.new('no backtrace')
        e.set_backtrace('')
        raise e
      rescue Exception => e
        msg = "Exception trying to create/update public ip #{public_ip_address.name} from resource group: #{resource_group_name}"
        puts "***FAULT:FATAL=#{msg}"
        Chef::Log.error("Azure::PublicIp - Exception is: #{e.message}")
        e = Exception.new('no backtrace')
        e.set_backtrace('')
        raise e
      end
    end

    # this fuction checks whether the public ip belongs to the given resource group 
    def check_existence_publicip(resource_group_name, public_ip_name)
      begin
        promise = @client.public_ip_addresses.get(resource_group_name, public_ip_name)
        response = promise.value!
        result = response.body
        return true
      rescue  MsRestAzure::AzureOperationError =>e
        Chef::Log.info("Azure::PublicIp - Exception is: #{e.body}")
        error_response = e.body["error"]
        Chef::Log.info("Error Response code:" +error_response["code"])
        if(error_response["code"] == "ResourceNotFound")
          return false
        else
          return true
        end
      rescue Exception => e
        msg = "Exception trying to get public ip #{public_ip_name} from resource group: #{resource_group_name}"
        Chef::Log.error("Azure::PublicIp -#{msg}")
        puts "***FAULT:FATAL="+e.body.to_s
        Chef::Log.error("Azure::PublicIp - Exception is: #{e.message}")
        e = Exception.new('no backtrace')
        e.set_backtrace('')
        raise e
      end
    end

  end
end
