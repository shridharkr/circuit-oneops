require File.expand_path('../../libraries/record_set.rb', __FILE__)
require File.expand_path('../../libraries/zone.rb', __FILE__)

::Chef::Recipe.send(:include, AzureDns)

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

include_recipe 'azuredns::get_azure_token'

cloud_name = node['workorder']['cloud']['ciName']
dns_attributes = node['workorder']['services']['dns'][cloud_name]['ciAttributes']

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'

Chef::Log.info("azuredns:set_dns_records.rb - platform-resource-group is: #{node['platform-resource-group']}")

if node.workorder.rfcCi.ciAttributes.has_key?('ptr_enabled') && node.workorder.rfcCi.ciAttributes.ptr_enabled == 'true'
  Chef::Log.info('azuredns:set_dns_records.rb - PTR Records are configured automatically in Azure DNS, ignoring')
end

# check to see if the zone exists in Azure
# if it doesn't create it
zone = AzureDns::Zone.new(dns_attributes, node['azure_rest_token'], node['platform-resource-group'])
zone_exist = zone.check_for_zone
if !zone_exist
  Chef::Log.info('azuredns:set_dns_records.rb - Zone does not exist')
  zone.create
end

# check the node for entries to delete and entries to create
if node.has_key?('deletable_entries')
  # not sure what I need to do with these deletable entries for Azure DNS?
  Chef::Log.info("azuredns:set_dns_records.rb - Deletable Entries are: #{node['deletable_entries']}")
end
if node.has_key?('entries')
  Chef::Log.info("azuredns:set_dns_records.rb - Entries are: #{node['entries']}")
else
  msg = 'missing entries failing'
  Chef::Log.error(msg)
  puts "***FAULT:FATAL=#{msg}"
  e = Exception.new('no backtrace')
  e.set_backtrace('')
  raise e
end

recordset = AzureDns::RecordSet.new(dns_attributes, node['azure_rest_token'], node['platform-resource-group'])
# we need to send Azure all the records to set at the same time
# get the records that currently exist for the A and CNAME types
# figure out the final list and call Azure to set it.
# basically looping for each record set and setting the A or CNAME entries
node['entries'].each do |entry|
  # dns_name will be the record set created/updated in azure dns
  dns_name = entry['name']
  # dns_value will be the A or CNAME records put on the record sets
  dns_values = entry['values'].is_a?(String) ? Array.new([entry['values']]) : entry['values']
  Chef::Log.info("azuredns:set_dns_records.rb - dns_name is: #{dns_name}")
  Chef::Log.info("azuredns:set_dns_records.rb - dns_values are: #{dns_values}")

  record_type = get_record_type(dns_values)
  Chef::Log.info("azuredns:set_dns_records.rb - record_type is: #{record_type}")

  # check for existing records on the record-set
  total_record_list = recordset.get_existing_records_for_recordset(record_type.upcase, dns_name)

  case record_type
  when 'a'
    # there can be multiple A records on the record set
    # loop through and add each of them to the total array list
    # add the dns_values to the existing array
    dns_values.each do |value|
      if node['dns_action'] == 'create'
        # if the value is already in the list, skip to the next value
        next if total_record_list.include?(value)
        total_record_list.push(value)
      else # delete
        total_record_list.delete(value)
      end
    end
    Chef::Log.info("azuredns:set_dns_records.rb - Total Record list is: #{total_record_list}")
    if total_record_list.size > 0
      # create/update the record set
      Chef::Log.info("azuredns:set_dns_records.rb - Would create dns_name: #{dns_name}, records: #{total_record_list}, for record type: #{record_type.upcase}")
      recordset.set_records_on_record_set(dns_name, total_record_list, record_type.upcase)
    else
      # delete the record set
      recordset.remove_record_set(dns_name, record_type.upcase)
    end
  when 'cname'
    # check if the value we are trying to set is the same as the existing one
    # if it is, skip to the next entry
    Chef::Log.info("azuredns:set_dns_records.rb - first entry in total_record_list is: #{total_record_list.first}")
    Chef::Log.info("azuredns:set_dns_records.rb - dns_values is: #{dns_values}")
    next if total_record_list.first == dns_values
    # if they aren't the same, set total_record_list to the new value the customer wants to set
    total_record_list = dns_values
    Chef::Log.info("azuredns:set_dns_records.rb - total_record_list is: #{total_record_list}")

    if node['dns_action'] == 'create'
      # create/update the record set
      Chef::Log.info("azuredns:set_dns_records.rb - Would create dns_name: #{dns_name}, records: #{total_record_list}, for record type: #{record_type.upcase}")
      recordset.set_records_on_record_set(dns_name, total_record_list, record_type.upcase)
    else # delete
      # delete the record set
      recordset.remove_record_set(dns_name, record_type.upcase)
    end

  end

end
