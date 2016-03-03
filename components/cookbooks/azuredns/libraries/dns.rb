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
      @recordset = AzureDns::RecordSet.new(@dns_attributes, @azure_rest_token, @platform_resource_group)
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
    def validate_customer_domain(customer_domain)
      if node.customer_domain !~ /^\./
        customer_domain = '.'+node.customer_domain
      end
      customer_domain
    end
    #below function might cause error due to its return statement
    def checking_platform(box)
      # skip in active (A/B update)
      if box.has_key?(:is_active) && box[:is_active] == 'false'
        Chef::Log.info('azuredns:remove_old_aliases.rb - skipping due to platform is_active false')
        return
      end
    end

    def checking_cloud_dns_id(service_attrs,cloud_service)
      if service_attrs['cloud_dns_id'].nil? || service_attrs['cloud_dns_id'].empty?
        msg = "azuredns:remove_old_aliases.rb - no cloud_dns_id for dns cloud service: #{cloud_service['nsPath']} #{cloud_service['ciName']}"
        Chef::Log.error(msg)
        puts "***FAULT:FATAL=#{msg}"
        e = Exception.new('no backtrace')
        e.set_backtrace('')
        raise e
      end
    end

    def checking_hostname_entry(node_workorder_payload)
      is_hostname_entry = false
      if !node_workorder_payload.has_key?('Entrypoint')
        is_hostname_entry = true
      end
      is_hostname_entry
    end

    def get_aliases(node_workorder_rfcci_json,is_hostname_entry)
      aliases = Array.new
      if node_workorder_rfcci_json.ciBaseAttributes.has_key?("aliases") && !is_hostname_entry
        begin
          aliases = JSON.parse(node_workorder_rfcci_json.ciBaseAttributes.aliases)
        rescue Exception =>e
          Chef::Log.info("azuredns:remove_old_aliases.rb - could not parse aliases json: "+node_workorder_rfcci_json.ciBaseAttributes.aliases)
        end
      end
      aliases
    end

    def get_current_aliases(node_workorder_rfcci_json,is_hostname_entry)
      current_aliases = Array.new
      if node_workorder_rfcci_json.ciAttributes.has_key?("aliases") && !is_hostname_entry
        begin
          current_aliases = JSON.parse(node_workorder_rfcci_json.ciAttributes.aliases)
        rescue Exception =>e
          Chef::Log.info("azuredns:remove_old_aliases.rb - could not parse aliases json: "+node_workorder_rfcci_json.ciAttributes.aliases)
        end
      end
      current_aliases
    end

    def remove_current_aliases(aliases,current_aliases)
      # if I don't have any previous aliases, no need to remove the current aliases from the list to delete.
      if !aliases.nil?
        if !current_aliases.nil?
          current_aliases.each do |active_alias|
            aliases.delete(active_alias)
          end
        end
      end
      aliases
    end

    def get_full_aliases(node_workorder_rfcci_json,is_hostname_entry)
      full_aliases = Array.new

      if node_workorder_rfcci_json.ciBaseAttributes.has_key?("full_aliases") && !is_hostname_entry
        begin
          full_aliases = JSON.parse(node_workorder_rfcci_json.ciBaseAttributes.full_aliases)
        rescue Exception =>e
          Chef::Log.info("azuredns:remove_old_aliases.rb - could not parse full_aliases json: "+node_workorder_rfcci_json.ciBaseAttributes.full_aliases)
        end
      end
      full_aliases
    end

    def get_current_full_aliases(node_workorder_rfcci_json,is_hostname_entry)
      current_full_aliases = Array.new

      if node_workorder_rfcci_json.ciAttributes.has_key?("full_aliases") && !is_hostname_entry
        begin
          current_full_aliases = JSON.parse(node_workorder_rfcci_json.ciAttributes.full_aliases)
        rescue Exception =>e
          Chef::Log.info("azuredns:remove_old_aliases.rb - could not parse full_aliases json: "+node_workorder_rfcci_json.ciAttributes.full_aliases)
        end
      end
      current_full_aliases
    end

    def remove_current_full_aliases(full_aliases,current_full_aliases)
      # if I don't have any previous aliases, no need to remove the current aliases from the list to delete.
      if !full_aliases.nil?
        if !current_full_aliases.nil?
          current_full_aliases.each do |active_full_alias|
            full_aliases.delete(active_full_alias)
          end
        end
      end
      full_aliases
    end

    def set_alias_entries_to_be_deleted(aliases,customer_domain,priority,cloud_dns_id, record_set)

      entries = Array.new

      if !aliases.nil?
        # cloud-level short aliases
        aliases.each do |a|
          next if a.empty?
          alias_name = a + customer_domain
          Chef::Log.info("azuredns:remove_old_aliases.rb - alias_name is: #{alias_name}")

          # get the value from azure
          value = record_set.get_existing_records_for_recordset('CNAME', alias_name)

          if !value.nil?
            Chef::Log.info("azuredns:remove_old_aliases.rb - short alias dns_name: #{alias_name} value: #{value.first}")
            entries.push({:name => alias_name, :values => value.first })
            # deletable_entries.push({:name => alias_name, :values => value.first })
          else
            Chef::Log.info("azuredns:remove_old_aliases.rb - Nothing to remove")
          end

          if priority == '1'

            alias_platform_dns_name = alias_name.gsub("\."+cloud_dns_id,'').downcase
            Chef::Log.info("azuredns:remove_old_aliases.rb - alias_platform_dns_name is: #{alias_platform_dns_name}")
            # get the value from azure
            value = record_set.get_existing_records_for_recordset('CNAME', alias_platform_dns_name)
            if !value.nil?
              entries.push({:name => alias_platform_dns_name, :values => value.first })
            else
              Chef::Log.info('azuredns:remove_old_aliases.rb - Nothing to remove')
            end

          end
        end
      end
      entries
    end

    def set_full_alias_entries_to_be_deleted(full_aliases,record_set,entries)
      if !full_aliases.nil?
        full_aliases.each do |full|
          # only cleaning up old CNAME aliases
          full_value = record_set.get_existing_records_for_recordset('CNAME', full)

          Chef::Log.info("azuredns:remove_old_aliases.rb - full alias dns_name: #{full} values: #{full_value.first}")
          entries.push({:name => full, :values => full_value.first })
          # deletable_entries.push({:name => full, :values => full_value})
        end
      end
    end

    def remove_record_set_from_azure(entries,record_set)
      if !entries.nil?
        # for each entry, remove the record set from azure
        entries.each do |entry|
          name = entry[:name]
          Chef::Log.info("azuredns:remove_old_aliases.rb - removing entry: #{name}")
          record_set.remove_record_set(name, 'CNAME')
          Chef::Log.info('azuredns:remove_old_aliases.rb - entry removed')
        end
      end
    end
  end
end

