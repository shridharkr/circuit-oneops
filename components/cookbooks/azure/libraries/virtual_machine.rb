module AzureCompute

  class VirtualMachine
    attr_reader :client, :subscription_id

    def initialize(credentials, subscription_id)
      @client = Azure::ARM::Compute::ComputeManagementClient.new(credentials)
      @client.subscription_id = subscription_id
      @subscription_id = subscription_id
    end

    def get_subscription_vms
      begin
        puts("Fetching virtual machines from subscription")
        start_time = Time.now.to_i
        promise = @client.virtual_machines.list_all()
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        puts("operation took #{duration} seconds")
        return result
      rescue MsRest::DeserializationError => ex
        puts("Error getting subscription VMs")
        puts("Error: #{ex.message}")
        puts("Error Message: #{ex.exception_message}")
        puts("Error Body: #{ex.response_body}")
        result = Azure::ARM::Compute::Models::VirtualMachineListResult.new
        return result
      rescue  MsRestAzure::AzureOperationError =>e
        puts("Error getting subscription VMs")
        puts("Error Response: #{e.response}")
        puts("Error Body: #{e.body}")
        result = Azure::ARM::Compute::Models::VirtualMachineListResult.new
        return result
      end
    end

    def get_resource_group_vms(resource_group_name)
      begin
        puts("Fetcing virtual machines in '#{resource_group_name}'")
        start_time = Time.now.to_i
        promise = @client.virtual_machines.list(resource_group_name)
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        puts("operation took #{duration} seconds")
        return result
      rescue  MsRestAzure::AzureOperationError =>e
        puts("Error getting resource group VM")
        puts("Error Response: #{e.response}")
        puts("Error Body: #{e.body}")
        result = Azure::ARM::Compute::Models::VirtualMachineListResult.new
        return result
      end

    end

    def get(resource_group_name, vm_name)
      begin
        puts("Fetching VM '#{vm_name}' in '#{resource_group_name}' ")
        start_time = Time.now.to_i
        promise = @client.virtual_machines.get(resource_group_name, vm_name)
        response = promise.value!
        result = response.body
        end_time = Time.now.to_i
        duration = end_time - start_time
        puts("operation took #{duration} seconds")
        return result
      rescue  MsRestAzure::AzureOperationError =>e
        puts("Error fetching VM")
        puts("Error Response: #{e.response}")
        puts("Error Body: #{e.body}")
        # result = Azure::ARM::Compute::Models::VirtualMachine.new
        return nil
      end
    end

  end

end