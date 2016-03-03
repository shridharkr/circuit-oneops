module AzureDns
  class DNS
    def initialize(platform_resource_group, azure_rest_token, dns_attributes)
      @platform_resource_group = platform_resource_group
      @azure_rest_token = azure_rest_token
      @dns_attributes = dns_attributes
    end

    # get dns record type - check for ip addresses
    def get_record_type (dns_values)
      # default to CNAME
      record_type = 'cname'
      # if the value is an IP then it is an 'A' record
      ips = dns_values.grep(/\d+\.\d+\.\d+\.\d+/)
      if ips.size > 0
        record_type = 'a'
      end
      return record_type
    end

    def create_zone
      zone = AzureDns::Zone.new(@dns_attributes, @azure_rest_token, @platform_resource_group)
      zone_exist = zone.check_for_zone
      if !zone_exist
        Chef::Log.info('azuredns:dns.rb - Zone does not exist')
        zone.create
      end
    end

    def set_dns_records(entries, dns_action, ttl)
      recordset = AzureDns::RecordSet.new(@dns_attributes, @azure_rest_token, @platform_resource_group)
      # we need to send Azure all the records to set at the same time
      # get the records that currently exist for the A and CNAME types
      # figure out the final list and call Azure to set it.
      # basically looping for each record set and setting the A or CNAME entries
      entries.each do |entry|
        # dns_name will be the record set created/updated in azure dns
        dns_name = entry['name']
        # dns_value will be the A or CNAME records put on the record sets
        dns_values = entry['values'].is_a?(String) ? Array.new([entry['values']]) : entry['values']
        Chef::Log.info("azuredns:dns.rb - dns_name is: #{dns_name}")
        Chef::Log.info("azuredns:dns.rb - dns_values are: #{dns_values}")

        record_type = get_record_type(dns_values)
        Chef::Log.info("azuredns:dns.rb - record_type is: #{record_type}")

        # check for existing records on the record-set
        total_record_list = recordset.get_existing_records_for_recordset(record_type.upcase, dns_name)

        case record_type
          when 'a'
            # there can be multiple A records on the record set
            # loop through and add each of them to the total array list
            # add the dns_values to the existing array
            dns_values.each do |value|
              if dns_action == 'create'
                # if the value is already in the list, skip to the next value
                next if total_record_list.include?(value)
                total_record_list.push(value)
              else # delete
                total_record_list.delete(value)
              end
            end
            Chef::Log.info("azuredns:dns.rb - Total Record list is: #{total_record_list}")
            if total_record_list.size > 0
              # create/update the record set
              Chef::Log.info("azuredns:dns.rb - Would create dns_name: #{dns_name}, records: #{total_record_list}, for record type: #{record_type.upcase}")
              recordset.set_records_on_record_set(dns_name, total_record_list, record_type.upcase, ttl)
            else
              # delete the record set
              recordset.remove_record_set(dns_name, record_type.upcase)
            end
          when 'cname'
            # check if the value we are trying to set is the same as the existing one
            # if it is, skip to the next entry
            Chef::Log.info("azuredns:dns.rb - first entry in total_record_list is: #{total_record_list.first}")
            Chef::Log.info("azuredns:dns.rb - dns_values is: #{dns_values}")
            next if total_record_list.first == dns_values
            # if they aren't the same, set total_record_list to the new value the customer wants to set
            total_record_list = dns_values
            Chef::Log.info("azuredns:dns.rb - total_record_list is: #{total_record_list}")

            if dns_action == 'create'
              # create/update the record set
              Chef::Log.info("azuredns:dns.rb - Would create dns_name: #{dns_name}, records: #{total_record_list}, for record type: #{record_type.upcase}")
              recordset.set_records_on_record_set(dns_name, total_record_list, record_type.upcase, ttl)
            else # delete
              # delete the record set
              recordset.remove_record_set(dns_name, record_type.upcase)
            end
        end
      end
    end
  end
end

