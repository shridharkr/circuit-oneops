require 'chef'
require File.expand_path('../record_set.rb', __FILE__)
# **Rubocop Suppression**
# rubocop:disable LineLength
# rubocop:disable StringLiterals
# rubocop:disable MethodLength
# rubocop:disable PerceivedComplexity
# rubocop:disable AbcSize
# rubocop:disable ClassLength
module AzureDns
  # This class is performing tasks of removing old aliases
  class DNS
    attr_accessor :recordset
    attr_accessor :entries

    def initialize(service_attrs, azure_rest_token, node_resource_group)
      # object of Record Set Class
      @recordset = AzureDns::RecordSet.new(service_attrs, azure_rest_token, node_resource_group)
      # entries Array of {name:String, values:Array}
      @entries = []
      @aliases = []
      @current_aliases = []
      @full_aliases = []
      @current_full_aliases = []
    end

    def validate_customer_domain(customer_domain)
      valid_customer_domain = '.' + customer_domain if customer_domain !~ /^\./
      valid_customer_domain
    end

    def remove_zone_name(customer_domain, domain_name)
      # remove the zone name from the customer domain for azure.
      customer_domain = customer_domain.gsub('.' + domain_name, '')
      customer_domain
    end

    def checking_platform(box)
      # skip in active (A/B update)
      Chef::Log.info('azuredns:remove_old_aliases.rb - skipping due to platform is_active false') if box.key?(:is_active) && box[:is_active] == 'false'
    end

    def checking_cloud_dns_id(service_attrs, cloud_service)
      if service_attrs['cloud_dns_id'].nil? || service_attrs['cloud_dns_id'].empty?
        msg = "azuredns:remove_old_aliases.rb - no cloud_dns_id for dns cloud service: #{cloud_service['nsPath']} #{cloud_service['ciName']}"
        Chef::Log.error(msg)
        puts "***FAULT:FATAL=#{msg}"
        e = Exception.new('no backtrace')
        e.set_backtrace('')
        fail e
      end
      service_attrs['cloud_dns_id']
    end

    def checking_hostname_entry(node_workorder_payload)
      is_hostname_entry = false
      is_hostname_entry = true unless node_workorder_payload.key?('Entrypoint')
      is_hostname_entry
    end

    def remove_current_aliases_and_current_full_aliases(node_workorder_rfcci_json, is_hostname_entry)
      # getting aliases from workorder ciBaseAttributes
      get_aliases(node_workorder_rfcci_json, is_hostname_entry)

      # getting current/active aliases from workorder ciAttributes
      get_current_aliases(node_workorder_rfcci_json, is_hostname_entry)

      # removing active aliases from the array(aliases) to be deleted
      remove_current_aliases

      # getting full_aliases from workorder ciBaseAttributes
      get_full_aliases(node_workorder_rfcci_json, is_hostname_entry)

      # getting current/active full_aliases from workorder ciAttributes
      get_current_full_aliases(node_workorder_rfcci_json, is_hostname_entry)

      # removing active full aliases from the array(full aliases) to be deleted
      remove_current_full_aliases
    end

    def get_aliases(node_workorder_rfcci_json, is_hostname_entry)
      if node_workorder_rfcci_json['ciBaseAttributes'].key?("aliases") && !is_hostname_entry
        begin
          @aliases = JSON.parse(node_workorder_rfcci_json['ciBaseAttributes']['aliases'])
        rescue
          Chef::Log.info("azuredns:remove_old_aliases.rb - could not parse aliases json: " + node_workorder_rfcci_json['ciBaseAttributes']['aliases'])
        end
      end
      @aliases
    end

    def get_current_aliases(node_workorder_rfcci_json, is_hostname_entry)
      if node_workorder_rfcci_json['ciAttributes'].key?("aliases") && !is_hostname_entry
        begin
          @current_aliases = JSON.parse(node_workorder_rfcci_json['ciAttributes']['aliases'])
        rescue
          Chef::Log.info("azuredns:remove_old_aliases.rb - could not parse aliases json: " + node_workorder_rfcci_json['ciAttributes']['aliases'])
        end
      end
      @current_aliases
    end

    def remove_current_aliases
      # if I don't have any previous aliases, no need to remove the current aliases from the list to delete.
      @current_aliases.each do |active_alias|
        @aliases.delete(active_alias)
      end unless @current_aliases.nil? unless @aliases.nil?
    end

    def get_full_aliases(node_workorder_rfcci_json, is_hostname_entry)
      begin
        @full_aliases = JSON.parse(node_workorder_rfcci_json['ciBaseAttributes']['full_aliases'])
      rescue
        Chef::Log.info("azuredns:remove_old_aliases.rb - could not parse full_aliases json: " + node_workorder_rfcci_json['ciBaseAttributes']['full_aliases'])
      end if node_workorder_rfcci_json['ciBaseAttributes'].key?("full_aliases") && !is_hostname_entry
    end

    def get_current_full_aliases(node_workorder_rfcci_json, is_hostname_entry)
      begin
        @current_full_aliases = JSON.parse(node_workorder_rfcci_json['ciAttributes']['full_aliases'])
      rescue
        Chef::Log.info("azuredns:remove_old_aliases.rb - could not parse full_aliases json: " + node_workorder_rfcci_json['ciAttributes']['full_aliases'])
      end if node_workorder_rfcci_json['ciAttributes'].key?("full_aliases") && !is_hostname_entry
    end

    def remove_current_full_aliases
      # if I don't have any previous aliases, no need to remove the current aliases from the list to delete.
      @current_full_aliases.each do |active_full_alias|
        @full_aliases.delete(active_full_alias)
      end unless @current_full_aliases.nil? unless @full_aliases.nil?
    end

    def remove_old_aliases(customer_domain, priority, cloud_dns_id)
      # pushing aliases to be deleted in an entries array
      set_alias_entries_to_be_deleted(customer_domain, priority, cloud_dns_id)

      # pushing full aliases to be deleted in the same entries array used above
      set_full_alias_entries_to_be_deleted

      Chef::Log.info("azuredns:remove_old_aliases.rb - entries to remove are: #{@entries}")

      # For each entry, removing record sets from azure
      remove_record_set_from_azure
    end

    def set_alias_entries_to_be_deleted(customer_domain, priority, cloud_dns_id)
      unless @aliases.nil?
        # cloud-level short aliases
        @aliases.each do |a|
          next if a.empty?
          alias_name = a + customer_domain
          Chef::Log.info("azuredns:remove_old_aliases.rb - alias_name is: #{alias_name}")

          # get the value from azure
          value = @recordset.get_existing_records_for_recordset('CNAME', alias_name)
          if !value.nil?
            Chef::Log.info("azuredns:remove_old_aliases.rb - short alias dns_name: #{alias_name} value: #{value.first}")
            @entries.push(name: alias_name, values: value.first)

            # deletable_entries.push({:name => alias_name, :values => value.first })
          else
            Chef::Log.info("azuredns:remove_old_aliases.rb - Nothing to remove")
          end

          next if priority != '1'
          alias_platform_dns_name = alias_name.gsub("\." + cloud_dns_id, '').downcase
          Chef::Log.info("azuredns:remove_old_aliases.rb - alias_platform_dns_name is: #{alias_platform_dns_name}")
          # get the value from azure
          value = @recordset.get_existing_records_for_recordset('CNAME', alias_platform_dns_name)
          if !value.nil?
            @entries.push(name: alias_platform_dns_name, values: value.first)
          else
            Chef::Log.info('azuredns:remove_old_aliases.rb - Nothing to remove')
          end
        end
      end
      @entries
    end

    def set_full_alias_entries_to_be_deleted
      unless @full_aliases.nil?
        @full_aliases.each do |full|
          # only cleaning up old CNAME aliases
          full_value = @recordset.get_existing_records_for_recordset('CNAME', full)
          Chef::Log.info("azuredns:remove_old_aliases.rb- full alias dns_name: #{full} values: #{full_value.first}")
          @entries.push(name: full, values: full_value.first)
          # deletable_entries.push({name => full, :values => full_value})
        end
      end
      @entries
    end

    def remove_record_set_from_azure
      @entries.each do |entry|
        name = entry[:name]
        Chef::Log.info("azuredns:remove_old_aliases.rb - removing entry: #{name}")
        @recordset.remove_record_set(name, 'CNAME')
        Chef::Log.info('azuredns:remove_old_aliases.rb - entry removed')
      end unless @entries.nil?
    end
  end
end
