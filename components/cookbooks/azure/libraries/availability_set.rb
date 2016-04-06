require File.expand_path('../azure_utils.rb', __FILE__)

::Chef::Recipe.send(:include, AzureCommon)

# AzureCompute module for classes that are used in the compute step.
module AzureCompute
  # Class for all things Availability Sets that we do in OneOps for Azure.
  # get, add, delete, etc.
  class AvailabilitySet
    def initialize(compute_service)
      creds =
        AzureCommon::AzureUtils.get_credentials(compute_service['tenant_id'],
                                                compute_service['client_id'],
                                                compute_service['client_secret']
                                               )

      @client = Azure::ARM::Compute::ComputeManagementClient.new(creds)
      @client.subscription_id = compute_service['subscription']
    end

    # method will get the availability set using the resource group and
    # availability set name
    # will return whether or not the availability set exists.
    def get(resource_group, availability_set)
      begin
        promise =
          @client.availability_sets.get(resource_group,
                                        availability_set).value!
        promise.body
      rescue MsRestAzure::AzureOperationError => e
        # if the error is that the availability set doesn't exist,
        # just return a nil
        if e.response.status == 404
          puts 'Availability Set Not Found!  Create It!'
          return nil
        end
        puts("***FAULT:FATAL=#{e.body.values[0]['message']}")
        e = Exception.new('no backtrace')
        e.set_backtrace('')
        raise e
      rescue => ex
        puts("***FAULT:FATAL=#{ex.message}")
        ex = Exception.new('no backtrace')
        ex.set_backtrace('')
        raise ex
      end
    end

    # this method will add the availability set if needed.
    # it first checks to make sure the availability set exists,
    # if not, it will create it.
    def add(resource_group, availability_set, location)
      # check if it exists
      existance_promise = get(resource_group, availability_set)
      if !existance_promise.nil?
        Chef::Log.info("Availability Set #{existance_promise.name} exists
                        in the #{existance_promise.location} region.")
      else
        # need to create the availability set
        Chef::Log.info("Creating Availability Set
                        '#{availability_set}' in #{location} region")
        avail_set = get_avail_set_props(location)
        begin
          start_time = Time.now.to_i
          response =
            @client.availability_sets.create_or_update(resource_group,
                                                       availability_set,
                                                       avail_set).value!
          response.body
          end_time = Time.now.to_i
          duration = end_time - start_time
          Chef::Log.info("Availability Set created in #{duration} seconds")
        rescue MsRestAzure::AzureOperationError => e
          puts("***FAULT:FATAL=#{e.body.values[0]['message']}")
          e = Exception.new('no backtrace')
          e.set_backtrace('')
          raise e
        rescue => ex
          puts "***FAULT:FATAL=#{ex.message}"
          ex = Exception.new('no backtrace')
          ex.set_backtrace('')
          raise ex
        end
      end
    end

    private

    # create the properties object for creating availability sets
    def get_avail_set_props(location)
      avail_set_props =
        Azure::ARM::Compute::Models::AvailabilitySetProperties.new
      # At least two domain faults
      avail_set_props.platform_fault_domain_count = 2
      avail_set_props.platform_update_domain_count = 2
      # At this point we do not have virtual machines to include
      avail_set_props.virtual_machines = []
      avail_set_props.statuses = []
      avail_set = Azure::ARM::Compute::Models::AvailabilitySet.new
      avail_set.location = location
      avail_set.properties = avail_set_props
      avail_set
    end
  end
end
