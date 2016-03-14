# Class for all things Availability Sets that we do in OneOps for Azure.
module AzureCompute
  class AvailabilitySet

    def initialize(compute_service)
      creds = AzureCommon::AzureUtils.get_credentials(compute_service['tenant_id'], compute_service['client_id'], compute_service['client_secret'])

      @client = Azure::ARM::Compute::ComputeManagementClient.new(creds)
      @client.subscription_id = compute_service['subscription']
    end

    def get(platform_resource_group, platform_availability_set)
      begin
        promise = @client.availability_sets.get(platform_resource_group, platform_availability_set).value!
        promise.body
        # node.set['availability_set'] = promise.body
      rescue  MsRestAzure::AzureOperationError => e
        Chef::Log.error("***FAULT:Error getting availability set for resource group: #{resource_group_name} and availability set: #{availability_set_name} , exception=#{e.message}")
        e = Exception.new('no backtrace')
        e.set_backtrace('')
        raise e
      rescue Exception => ex
        Chef::Log.error("***FAULT:FATAL=#{ex.message}")
        ex = Exception.new('no backtrace')
        ex.set_backtrace('')
        raise ex
      end
    end

  end
end
