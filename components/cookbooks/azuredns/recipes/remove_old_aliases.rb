require File.expand_path('../../libraries/record_set.rb', __FILE__)
require File.expand_path('../../libraries/dns.rb', __FILE__)

cloud_name = node['workorder']['cloud']['ciName']
domain_name = node['workorder']['services']['dns'][cloud_name]['ciAttributes']['zone']

#object of DNS class
dns = AzureDns::DNS.new()

# ex) customer_domain: env.asm.org.oneops.com
customer_domain = dns.validate_customer_domain(node.customer_domain)
Chef::Log.info("azuredns:remove_old_aliases.rb - customer_domain is: #{customer_domain}")

# remove the zone name from the customer domain for azure.
customer_domain = customer_domain.gsub('.'+domain_name, '')
Chef::Log.info("azuredns:remove_old_aliases.rb - NEW customer_domain is: #{customer_domain}")

# Checking if the platform is active
# if active then skip
dns.checking_platform(node[:workorder][:box][:ciAttributes])

cloud_service = node['workorder']['services']['dns'][cloud_name]
service_attrs = cloud_service['ciAttributes']

# checking id cloud dns id is nil, if nil, throw an exception
dns.checking_cloud_dns_id(service_attrs,cloud_service)

# entries Array of {name:String, values:Array}
entries = Array.new
aliases = Array.new
current_aliases = Array.new
full_aliases = Array.new
current_full_aliases = Array.new

# this is a check to see if it is a hostname payload instead of fqdn
# we don't want to remove the aliases for fqdn if it is a hostname payload
is_hostname_entry = dns.checking_hostname_entry(node.workorder.payLoad)

# getting aliases from workorder ciBaseAttributes
aliases = dns.get_aliases(node.workorder.rfcCi,is_hostname_entry)

# getting current/active aliases from workorder ciAttributes
current_aliases = dns.get_current_aliases(node.workorder.rfcCi,is_hostname_entry)

# removing active aliases from the array(aliases) to be deleted
aliases = dns.remove_current_aliases(aliases,current_aliases)

# getting full_aliases from workorder ciBaseAttributes
full_aliases = dns.get_full_aliases(node.workorder.rfcCi,is_hostname_entry)

# getting current/active full_aliases from workorder ciAttributes
current_full_aliases = dns.get_current_full_aliases(node.workorder.rfcCi,is_hostname_entry)

# removing active full aliases from the array(full aliases) to be deleted
full_aliases = dns.remove_current_full_aliases(full_aliases,current_full_aliases)

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'

# get the azure token for making rest api calls to azure
include_recipe 'azuredns::get_azure_token'

# object of Record Set Class
recordset = AzureDns::RecordSet.new(service_attrs, node['azure_rest_token'], node['platform-resource-group'])

# getting priority from workorder json
priority = node.workorder.cloud.ciAttributes.priority

# pushing aliases to be deleted in an entries array
entries = dns.set_alias_entries_to_be_deleted(aliases,customer_domain,priority,service_attrs['cloud_dns_id'],recordset)

#pushing full aliases to be deleted in the same entries array used above
entries = dns.set_full_alias_entries_to_be_deleted(full_aliases,recordset,entries)

Chef::Log.info("azuredns:remove_old_aliases.rb - entries to remove are: #{entries}")

#For each entry, removing record sets from azure
dns.remove_record_set_from_azure(entries,recordset)
