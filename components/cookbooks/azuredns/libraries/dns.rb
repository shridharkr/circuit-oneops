# **Rubocop Suppression**
# rubocop:disable LineLength
# rubocop:disable MethodLength
# rubocop:disable AbcSize
require 'chef'
require File.expand_path('../record_set.rb', __FILE__)
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
    def normalize_customer_domain(customer_domain)
      valid_customer_domain = '.' + customer_domain if customer_domain !~ /^\./
      valid_customer_domain
    end

    def remove_zone_name_from_customer_domain(customer_domain, zone_name)
      customer_domain = customer_domain.gsub('.' + zone_name, '')
      customer_domain
    end

    def check_cloud_dns_id(service_attrs, cloud_service)
      if service_attrs['cloud_dns_id'].nil? || service_attrs['cloud_dns_id'].empty?
        msg = "azuredns:remove_old_aliases.rb - no cloud_dns_id for dns cloud service: #{cloud_service['nsPath']} #{cloud_service['ciName']}"
        Chef::Log.error(msg)
        puts "***FAULT:FATAL=#{msg}"
        e = Exception.new('no backtrace')
        e.set_backtrace('')
        fail e
      end
    end

    def entrypoint_exists(node_workorder_payload)
      !node_workorder_payload.key?('Entrypoint')
    end
    def remove_current_aliases_and_current_full_aliases(node_workorder_rfcci_json, is_hostname_entry)
      # getting aliases from workorder ciBaseAttributes
      get_aliases(node_workorder_rfcci_json, is_hostname_entry)

      # getting current/active aliases from workorder ciAttributes
      get_current_aliases(node_workorder_rfcci_json, is_hostname_entry)

      # removing active aliases from the array(aliases) to be deleted
      remove_current_aliases(node_workorder_rfcci_json, is_hostname_entry)

      # getting full_aliases from workorder ciBaseAttributes
      get_full_aliases(node_workorder_rfcci_json, is_hostname_entry)

      # getting current/active full_aliases from workorder ciAttributes
      get_current_full_aliases(node_workorder_rfcci_json, is_hostname_entry)

      # removing active full aliases from the array(full aliases) to be deleted
      remove_current_full_aliases(node_workorder_rfcci_json, is_hostname_entry)
    end

    def get_all_aliases(node_workorder_rfcci_json, is_hostname_entry, types)
      hash_of_all_aliases = []
      json_parse_result = []
      types.each do |type|
        node_ciBaseAttributes = node_workorder_rfcci_json['ciBaseAttributes']
        node_ciAttributes = node_workorder_rfcci_json['ciAttributes']
        if type == "aliases"
          node_attributes = node_ciBaseAttributes['aliases']
        elsif type == "full_aliases"
          node_attributes = node_ciBaseAttributes['full_aliases']
        elsif type == "current_aliases"
          node_attributes = node_ciAttributes['aliases']
        elsif type == "current_full_aliases"
          node_attributes = node_ciAttributes['full_aliases']
        end
        if node_ciBaseAttributes.key?('aliases') && node_ciBaseAttributes.key?('full_aliases') && node_ciAttributes.key?('aliases') && node_ciAttributes.key?('full_aliases') && !is_hostname_entry
          begin
            json_parse_result = JSON.parse(node_attributes)
          rescue
            Chef::Log.info('azuredns:remove_old_aliases.rb - could not parse ' + type + ' json: ' + node_attributes)
          end
          hash_of_all_aliases.push(name: type, values: json_parse_result)
        end
      end
      hash_of_all_aliases
    end

    def remove_all_aliases(node_workorder_rfcci_json, is_hostname_entry)
      hash_of_removed_aliases = []
      types = ['aliases', 'current_aliases', 'full_aliases', 'current_full_aliases']
      hash_of_all_aliases = get_all_aliases(node_workorder_rfcci_json,  is_hostname_entry, types)
      if !hash_of_all_aliases.empty?
      index = 0
      while index <= 3
        hash_aliase = hash_of_all_aliases.fetch(index)
        all_aliases = hash_aliase[:values]
        hash_current_aliase = hash_of_all_aliases.fetch(index + 1)
        all_current_aliases = hash_current_aliase[:values]
        all_current_aliases.each do |active_alias|
          all_aliases.delete(active_alias)
        end unless all_current_aliases.nil? unless all_aliases.nil?
        hash_of_removed_aliases.push(name: hash_aliase[:name], values: all_aliases)
        index+=2
      end
      end
      hash_of_removed_aliases
    end
    def remove_old_aliases(customer_domain, priority, cloud_dns_id, aliases, full_aliases)
      # pushing aliases to be deleted in an entries array
      entries = get_entries(customer_domain, priority, cloud_dns_id, aliases)

      # pushing full aliases to be deleted in the same entries array used above
      entries = get_updated_entries(entries, full_aliases)

      Chef::Log.info('azuredns:remove_old_aliases.rb - entries to remove are: #{entries}')

      # For each entry, removing record sets from azure
      delete_record_set(entries)
    end
    def get_entries(customer_domain, priority, cloud_dns_id, aliases)
      entries = []
      return if aliases.nil?
      # cloud-level short aliases
      aliases.each do |a|
        next if a.empty?
        alias_name = a + customer_domain
        Chef::Log.info("azuredns:remove_old_aliases.rb - alias_name is: #{alias_name}")

        # get the value from azure
        value = @recordset.get_existing_records_for_recordset('CNAME', alias_name)

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
          value = @recordset.get_existing_records_for_recordset('CNAME', alias_platform_dns_name)
          if !value.nil?
            entries.push({:name => alias_platform_dns_name, :values => value.first })
          else
            Chef::Log.info('azuredns:remove_old_aliases.rb - Nothing to remove')
          end

        end
      end
      entries
    end

    def get_updated_entries(entries, full_aliases)
      unless full_aliases.nil?
        full_aliases.each do |full_aliase|
          # only cleaning up old CNAME aliases
          full_value = @recordset.get_existing_records_for_recordset('CNAME', full_aliase)
          Chef::Log.info("azuredns:remove_old_aliases.rb- full alias dns_name: #{full_aliase} values: #{full_value.first}")
          entries.push(name: full_aliase, values: full_value.first)
        end
      end
      entries
    end

    def delete_record_set(entries)
      entries.each do |entry|
        name = entry[:name]
        Chef::Log.info("azuredns:remove_old_aliases.rb - removing entry: #{name}")
        @recordset.remove_record_set(name, 'CNAME')
        Chef::Log.info("azuredns:remove_old_aliases.rb - entry removed")
      end unless entries.nil?
    end
  end
end
