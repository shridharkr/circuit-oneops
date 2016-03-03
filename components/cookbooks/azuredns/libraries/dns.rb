module AzureDns
  class DNS
    def initialize()
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

