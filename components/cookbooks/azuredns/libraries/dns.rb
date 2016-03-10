# **Rubocop Suppression**
# rubocop:disable LineLength
# rubocop:disable MethodLength
# rubocop:disable AbcSize

require 'chef'
module AzureDns
  # Cookbook Name:: azuredns
  # Recipe:: set_dns_records
  #
  # This class handles following dns operations
  # a) set dns recordset
  # b) create zone
  #
  class DNS
    attr_accessor :recordset
    attr_accessor :zone

    def initialize(platform_resource_group, azure_rest_token, dns_attributes)
      @platform_resource_group = platform_resource_group
      @azure_rest_token = azure_rest_token
      @dns_attributes = dns_attributes
      @recordset = []
      @zone = nil
    end

    # get dns record type - check for ip addresses
    def get_record_type(dns_name, dns_values)
      # default to CNAME
      record_type = 'cname'
      # if the value is an IP then it is an 'A' record
      ips = dns_values.grep(/\d+\.\d+\.\d+\.\d+/)
      record_type = 'a' unless ips.empty?
      record_type = 'ptr' if dns_name =~ /^\d+\.\d+\.\d+\.\d+$/
      record_type
    end

    def create_zone
      @zone = AzureDns::Zone.new(@dns_attributes, @azure_rest_token, @platform_resource_group)
      zone_exist = @zone.check_for_zone
      unless zone_exist
        Chef::Log.info('azuredns:dns.rb - Zone does not exist')
        @zone.create
      end
    end

    def set_a_type_records(total_record_list, dns_action, dns_values, dns_name, ttl)
      record_type = 'a'
      # there can be multiple A records on the record set
      # loop through and add each of them to the total array list
      # add the dns_values to the existing array
      dns_values.each do |value|
        if dns_action == 'create'
          # if the value is already in the list, skip to the next value
          return if total_record_list.include?(value)
          total_record_list.push(value)
        else # delete
          total_record_list.delete(value)
        end
      end
      Chef::Log.info("azuredns:dns.rb - Total Record list is: #{total_record_list}")
      if !total_record_list.empty?
        # create/update the record set
        Chef::Log.info("azuredns:dns.rb - Would create dns_name: #{dns_name}, records: #{total_record_list}, for record type: #{record_type.upcase}")
        @recordset.set_records_on_record_set(dns_name, total_record_list, record_type.upcase, ttl)
      else
        # delete the record set
        @recordset.remove_record_set(dns_name, record_type.upcase)
      end
    end

    def set_cname_type_records(total_record_list, dns_action, dns_values, dns_name, ttl)
      record_type = 'cname'
      # check if the value we are trying to set is the same as the existing one
      # if it is, skip to the next entry
      Chef::Log.info("azuredns:dns.rb - first entry in total_record_list is: #{total_record_list.first}")
      Chef::Log.info("azuredns:dns.rb - dns_values is: #{dns_values}")
      return if total_record_list.first == dns_values
      # if they aren't the same, set total_record_list to the new value the customer wants to set
      total_record_list = dns_values
      Chef::Log.info("azuredns:dns.rb - total_record_list is: #{total_record_list}")

      if dns_action == 'create'
        # create/update the record set
        Chef::Log.info("azuredns:dns.rb - Would create dns_name: #{dns_name}, records: #{total_record_list}, for record type: #{record_type.upcase}")
        @recordset.set_records_on_record_set(dns_name, total_record_list, record_type.upcase, ttl)
      else # delete
        # delete the record set
        @recordset.remove_record_set(dns_name, record_type.upcase)
      end
    end

    def set_dns_records(entries, dns_action, ttl)
      @recordset = AzureDns::RecordSet.new(@dns_attributes, @azure_rest_token, @platform_resource_group)
      # we need to send Azure all the records to set at the same time
      # get the records that currently exist for the A and CNAME types
      # figure out the final list and call Azure to set it.
      # basically looping for each record set and setting the A or CNAME entries
      entries.each do |entry|
        # need to remove the zone name from the end of the record set name.  Azure will auto append the zone to the recordset
        # name internally.
        # dns_name will be the record set created/updated in azure dns
        dns_name = entry['name'].sub('.' + @dns_attributes['zone'], '')
        Chef::Log.info("azuredns:set_dns_records.rb - dns_name is: #{dns_name}")

        # dns_value will be the A or CNAME records put on the record sets
        dns_values = entry['values'].is_a?(String) ? Array.new([entry['values']]) : entry['values']
        Chef::Log.info("azuredns:dns.rb - dns_name is: #{dns_name}")
        Chef::Log.info("azuredns:dns.rb - dns_values are: #{dns_values}")

        record_type = get_record_type(dns_name, dns_values)

        Chef::Log.info("azuredns:dns.rb - record_type is: #{record_type}")

        # check for existing records on the record-set
        total_record_list = @recordset.get_existing_records_for_recordset(record_type.upcase, dns_name)

        case record_type
        when 'a'
          set_a_type_records(total_record_list, dns_action, dns_values, dns_name, ttl)
        when 'cname'
          set_cname_type_records(total_record_list, dns_action, dns_values, dns_name, ttl)
        when 'ptr'
          Chef::Log.info('Record Type is PTR. PTR records are not yet supported for Azure.')
        end
      end
    end
  end
end
