require File.expand_path('../../libraries/record_set.rb', __FILE__)
require File.expand_path('../../libraries/zone.rb', __FILE__)
require File.expand_path('../../libraries/dns.rb', __FILE__)

::Chef::Recipe.send(:include, AzureDns)

include_recipe 'azuredns::get_azure_token'

cloud_name = node['workorder']['cloud']['ciName']
dns_attributes = node['workorder']['services']['dns'][cloud_name]['ciAttributes']

ttl = node['workorder']['rfcCi']['ciAttributes']['ttl']
Chef::Log.info("TTL IS: #{ttl}")

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'

Chef::Log.info("azuredns:set_dns_records.rb - platform-resource-group is: #{node['platform-resource-group']}")

if node.workorder.rfcCi.ciAttributes.has_key?('ptr_enabled') && node.workorder.rfcCi.ciAttributes.ptr_enabled == 'true'
  Chef::Log.info('azuredns:set_dns_records.rb - PTR Records are configured automatically in Azure DNS, ignoring')
end

dns = AzureDns::DNS.new(node['platform-resource-group'], node['azure_rest_token'], dns_attributes)

# check to see if the zone exists in Azure
# if it doesn't create it
dns.create_zone

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

dns.set_dns_records(node['entries'], node['dns_action'], ttl)
