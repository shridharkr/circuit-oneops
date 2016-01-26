require 'azure_mgmt_compute'

::Chef::Recipe.send(:include, Azure::ARM::Compute)
::Chef::Recipe.send(:include, Azure::ARM::Compute::Models)

cloud_name = node[:workorder][:cloud][:ciName]
compute_service = node[:workorder][:services][:compute][cloud_name][:ciAttributes]
subscription_id = compute_service[:subscription]

location = compute_service[:location]
Chef::Log.info("Cloud Location: #{location}")

begin
  client = ComputeManagementClient.new(node[:azureCredentials])
  client.subscription_id = subscription_id

  # First, check if availability set is already created
  existance_promise = client.availability_sets.get(node['platform-resource-group'], node['platform-availability-set'])
  response = existance_promise.value!
  result = response.body

  Chef::Log.info("Availability Set #{node['platform-availability-set']} already exists. No need to create.")

rescue MsRestAzure::AzureOperationError => e
  Chef::Log.warn("AzureOperationError Response: #{e.response}")
  Chef::Log.warn("AzureOperationError Body: #{e.body}")

  begin

    avail_set_props = AvailabilitySetProperties.new
    # At least two domain faults
    avail_set_props.platform_fault_domain_count = 2
    avail_set_props.platform_update_domain_count = 2
    # At this point we do not have virtual machines to include
    avail_set_props.virtual_machines = []
    avail_set_props.statuses = []

    avail_set = Azure::ARM::Compute::Models::AvailabilitySet.new
    avail_set.location = location
    avail_set.properties = avail_set_props

    Chef::Log.info("Creating Availability Set '#{node['platform-availability-set']}'")
    start_time = Time.now.to_i
    promise = client.availability_sets.create_or_update(node['platform-resource-group'], node['platform-availability-set'], avail_set)
    response = promise.value!
    result = response.body
    end_time = Time.now.to_i

    duration = end_time - start_time

    puts("Availability Set created in #{duration} seconds")

  rescue MsRestAzure::AzureOperationError => e
    puts "***FAULT:FATAL="+e.message
    Chef::Log.error("AzureOperationError Response: #{e.response}")
    Chef::Log.error("AzureOperationError Body: #{e.body}")
    e = Exception.new('no backtrace')
    e.set_backtrace('')
    raise e
  rescue Exception =>ex
    puts "***FAULT:FATAL="+ex.message
    raise ex
  end
end

Chef::Log.info("Exiting add availability set")
