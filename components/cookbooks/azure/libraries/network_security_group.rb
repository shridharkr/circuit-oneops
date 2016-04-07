require 'azure_mgmt_network'

module AzureNetwork

  class NetworkSecurityGroup
    include Azure::ARM::Network
    include Azure::ARM::Network::Models
    
    def initialize(credentials, subscription_id)
      @client = Azure::ARM::Network::NetworkResourceProviderClient.new(credentials)
      @client.subscription_id = subscription_id
    end
    
    def get(resource_group_name, network_security_group_name)
      begin
        promise = @client.network_security_groups.get(resource_group_name, network_security_group_name)
        response = promise.value!
        result = response.body
        result
        rescue  MsRestAzure::AzureOperationError =>e
          Chef::Log.error("Error getting NSG '#{network_security_group_name}'")
          Chef::Log.error("Error Response: #{e.response}")
          Chef::Log.error("Error Body: #{e.body}")
          return nil
        rescue Exception => e
          msg = "Exception trying to get network security group #{network_security_group_name} from resource group: #{resource_group_name}"
          Chef::Log.error("Azure::Network Security group -#{msg}")
          puts "***FAULT:FATAL="+e.body.to_s
          Chef::Log.error("Azure::Network Security group - Exception is: #{e.message}")
          e = Exception.new('no backtrace')
          e.set_backtrace('')
          raise e
      end
    end
    
    def create(resource_group_name, net_sec_group_name, location)
      begin
        parameters = Azure::ARM::Network::Models::NetworkSecurityGroup.new
        parameters.location = location

        nsg_props = NetworkSecurityGroupPropertiesFormat.new
        parameters.properties = nsg_props

        promise = @client.network_security_groups.create_or_update(resource_group_name,net_sec_group_name,parameters)
        response = promise.value!
        result = response.body
        result

        rescue MsRestAzure::AzureOperationError => e
        Chef::Log.error("Error  creating network security group in '#{resource_group_name}'")
        Chef::Log.error("Error response: #{e.response}")
        Chef::Log.error("Error Body: #{e.body}")
        return nil
        rescue Exception => e
          msg = "Exception trying to create network security group #{network_security_group_name} from resource group: #{resource_group_name}"
          Chef::Log.error("Azure::Network Security group -#{msg}")
          puts "***FAULT:FATAL="+e.body.to_s
          Chef::Log.error("Azure::Network Security group - Exception is: #{e.message}")
          e = Exception.new('no backtrace')
          e.set_backtrace('')
          raise e
      end
    end
    
    def create_update(resource_group_name, net_sec_group_name, parameters )
      begin
        promise = @client.network_security_groups.create_or_update(resource_group_name,net_sec_group_name,parameters)
        response = promise.value!
        result = response.body
        result

        rescue MsRestAzure::AzureOperationError => e
        Chef::Log.error("Error  creating network security group in '#{resource_group_name}'")
        Chef::Log.error("Error response: #{e.response}")
        Chef::Log.error("Error Body: #{e.body}")
        return nil
        rescue Exception => e
          msg = "Exception trying to create/update network security group #{network_security_group_name} from resource group: #{resource_group_name}"
          Chef::Log.error("Azure::Network Security group -#{msg}")
          puts "***FAULT:FATAL="+e.body.to_s
          Chef::Log.error("Azure::Network Security group - Exception is: #{e.message}")
          e = Exception.new('no backtrace')
          e.set_backtrace('')
          raise e
      end
    end
    
    def list_security_groups(resource_group_name)
      begin
        promise = @client.network_security_groups.list(resource_group_name)
        response = promise.value!
        result = response.body
        result

        rescue  MsRestAzure::AzureOperationError => e
        Chef::Log.error("Error getting network security groups in   '#{resource_group_name}' ")
        Chef::Log.error("Error Response: #{e.response}")
        Chef::Log.error("Error Body: #{e.body}")
        return nil
        rescue Exception => e
          msg = "Exception trying to list network security groups from #{resource_group_name} resource group"
          Chef::Log.error("Azure::Network Security group -#{msg}")
          puts "***FAULT:FATAL="+e.body.to_s
          Chef::Log.error("Azure::Network Security group - Exception is: #{e.message}")
          e = Exception.new('no backtrace')
          e.set_backtrace('')
          raise e
      end
    end
    
    def delete_security_group(resource_group_name, net_sec_group_name)
      begin
        promise = @client.network_security_groups.delete(resource_group_name, net_sec_group_name)
        response = promise.value!
        result = response.body
        result

        rescue  MsRestAzure::AzureOperationError => e
        Chef::Log.error("Error deleting NSG #{resource_group_name}")
        Chef::Log.error("Error Response: #{e.response}")
        Chef::Log.error("Error Body: #{e.body}")
        return nil
        rescue Exception => e
          msg = "Exception trying to delete network security group #{net_sec_group_name} from resource group: #{resource_group_name}"
          Chef::Log.error("Azure::Network Security group -#{msg}")
          puts "***FAULT:FATAL="+e.body.to_s
          Chef::Log.error("Azure::Network Security group - Exception is: #{e.message}")
          e = Exception.new('no backtrace')
          e.set_backtrace('')
          raise e
      end
    end
    
    def create_or_update_rule(resource_group_name, network_security_group_name, security_rule_name, security_rule_parameters = nil)
      # The Put network security rule operation creates/updates a security rule in the specified network security group group.
      begin
        secrule = SecurityRule.new
        secrule.properties = security_rule_parameters

        promise = SecurityRules.new(@client).create_or_update(resource_group_name, network_security_group_name, security_rule_name, secrule)
        response = promise.value!
        result = response.body
        result

      rescue  MsRestAzure::AzureOperationError => e
        Chef::Log.error("Error trying to get the '#{security_rule_name}' Security Rule")
        Chef::Log.error("Error Response: #{e.response}")
        Chef::Log.error("Error Body: #{e.body}")
        return nil
      rescue Exception => e
        msg = "Exception trying to create/update security rule #{security_rule_name} in securtiry group: #{network_security_group_name}"
        Chef::Log.error("Azure::Network Security group -#{msg}")
        puts "***FAULT:FATAL="+e.body.to_s
        Chef::Log.error("Azure::Network Security group - Exception is: #{e.message}")
        e = Exception.new('no backtrace')
        e.set_backtrace('')
        raise e
      end
    end
    
    def delete_rule(resource_group_name, network_security_group_name, security_rule_name)
      # The delete network security rule operation deletes the specified network security rule.
      begin
        promise = SecurityRules.new(@client).delete(resource_group_name, network_security_group_name, security_rule_name)
        response = promise.value!
        result = response.body
        result

      rescue  MsRestAzure::AzureOperationError => e
        Chef::Log.error("Error trying to delete the '#{security_rule_name}' Security Rule")
        Chef::Log.error("Error Response: #{e.response}")
        Chef::Log.error("Error Body: #{e.body}")
        return nil
      rescue Exception => e
        msg = "Exception trying to delete security rule #{security_rule_name} from securtiry group: #{network_security_group_name}"
        Chef::Log.error("Azure::Network Security group -#{msg}")
        puts "***FAULT:FATAL="+e.body.to_s
        Chef::Log.error("Azure::Network Security group - Exception is: #{e.message}")
        e = Exception.new('no backtrace')
        e.set_backtrace('')
        raise e
      end
    end
    
    def get_rule(resource_group_name, network_security_group_name, security_rule_name, custom_headers = nil)
      #The Get NetworkSecurityRule operation retreives information about the specified network security rule.
      begin
        promise = SecurityRules.new(@client).get(resource_group_name, network_security_group_name, security_rule_name)
        response = promise.value!
        result = response.body
        result

      rescue  MsRestAzure::AzureOperationError => e
        Chef::Log.error("Error trying to get the '#{security_rule_name}' Security Rule")
        Chef::Log.error("Error Response: #{e.response}")
        Chef::Log.error("Error Body: #{e.body}")
        return nil
      rescue Exception => e
        msg = "Exception trying to get security rule #{security_rule_name} from securtiry group: #{network_security_group_name}"
        Chef::Log.error("Azure::Network Security group -#{msg}")
        puts "***FAULT:FATAL="+e.body.to_s
        Chef::Log.error("Azure::Network Security group - Exception is: #{e.message}")
        e = Exception.new('no backtrace')
        e.set_backtrace('')
        raise e
      end
    end
    
    def list_rules(resource_group_name, network_security_group_name)
      # The List network security rule opertion retrieves all the security rules in a network security group.
      begin
        promise = SecurityRules.new(@client).list(resource_group_name, network_security_group_name)
        response = promise.value!
        result = response.body
        result

      rescue  MsRestAzure::AzureOperationError => e
        Chef::Log.error("Error trying to listing Security Rules in '#{resource_group_name}' ")
        Chef::Log.error("Error Response: #{e.response}")
        Chef::Log.error("Error Body: #{e.body}")
        return nil
      rescue Exception => e
        msg = "Exception trying to list security rules from securtiry group: #{network_security_group_name}"
        Chef::Log.error("Azure::Network Security group -#{msg}")
        puts "***FAULT:FATAL="+e.body.to_s
        Chef::Log.error("Azure::Network Security group - Exception is: #{e.message}")
        e = Exception.new('no backtrace')
        e.set_backtrace('')
        raise e
      end
    end
    
    
    def self.create_rule_properties(security_rule_name,access,description, destination_address_prefix, destination_port_range,direction, priority, protocol, provisioning_state, source_address_prefix, source_port_range)
      #01 @security_rule_name ⇒ Security group name
      #02 @access ⇒ SecurityRuleAccess allow or denied.
      #03 @description ⇒ String to 140 chars
      #04 @destination_address_prefix ⇒ String source IP range
      #05 @destination_port_range ⇒ String range between 0 and 65535.
      #06 @direction ⇒ SecurityRuleDirection rule.InBound or Outbound.
      #07 @priority ⇒ Integer be between 100 and 4096.
      #08 @protocol ⇒ SecurityRuleProtocol applies to.
      #09 @provisioning_state ⇒ String resource Updating/Deleting/Failed.
      #10 @source_address_prefix ⇒ String range.
      #11 @source_port_range ⇒ String between 0 and 65535.

      sec_rule = Azure::ARM::Network::Models::SecurityRule.new
      sec_rule.name = security_rule_name

      sec_rule_props = Azure::ARM::Network::Models::SecurityRulePropertiesFormat.new
      sec_rule_props.access = access
      sec_rule_props.description = description
      sec_rule_props.destination_address_prefix = destination_address_prefix
      sec_rule_props.destination_port_range = destination_port_range
      sec_rule_props.direction = direction
      sec_rule_props.priority = priority
      sec_rule_props.protocol = protocol
      sec_rule_props.provisioning_state = provisioning_state
      sec_rule_props.source_address_prefix = source_address_prefix
      sec_rule_props.source_port_range = source_port_range

      sec_rule.properties = sec_rule_props
      sec_rule
    end

  #end of class    
  end
#end of module
end