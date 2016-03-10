require File.expand_path('../../libraries/dns.rb', __FILE__)

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'

# get the azure token for making rest api calls to azure
include_recipe 'azuredns::get_azure_token'

cloud_name = node['workorder']['cloud']['ciName']
domain_name =
    node['workorder']['services']['dns'][cloud_name]['ciAttributes']['zone']

cloud_service = node['workorder']['services']['dns'][cloud_name]
service_attrs = cloud_service['ciAttributes']

# object of DNS class
dns = AzureDns::DNS.new(service_attrs, node['azure_rest_token'],
                        node['platform-resource-group'])

# ex) customer_domain: env.asm.org.oneops.com
customer_domain = dns.validate_customer_domain(node.customer_domain)

# remove the zone name from the customer domain for azure.
customer_domain = dns.remove_zone_name(customer_domain, domain_name)
Chef::Log.info("azuredns:remove_old_aliases.rb
               - NEW customer_domain is: #{customer_domain}")

# Checking if the platform is active
# if active then skip
dns.checking_platform(node['workorder']['box']['ciAttributes'])

# checking id cloud dns id is nil, if nil, throw an exception
dns.checking_cloud_dns_id(service_attrs, cloud_service)

# this is a check to see if it is a hostname payload instead of fqdn
# we don't want to remove the aliases for fqdn if it is a hostname payload
is_hostname_entry = dns.checking_hostname_entry(node.workorder.payLoad)
dns.remove_current_aliases_and_current_full_aliases(node.workorder.rfcCi,
                                         is_hostname_entry)

# getting priority from workorder json
priority = node.workorder.cloud.ciAttributes.priority
dns.remove_old_aliases(customer_domain, priority,
                         service_attrs['cloud_dns_id'])
