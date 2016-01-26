
cloud_name = node['workorder']['cloud']['ciName']
domain_name = node['workorder']['services']['dns'][cloud_name]['ciAttributes']['zone']

# ex) customer_domain: env.asm.org.oneops.com
customer_domain = node.customer_domain
if node.customer_domain !~ /^\./
  customer_domain = '.'+node.customer_domain
end
Chef::Log.info("azuredns:remove_old_aliases.rb - customer_domain is: #{customer_domain}")

# remove the zone name from the customer domain for azure.
customer_domain = customer_domain.gsub('.'+domain_name, '')
Chef::Log.info("azuredns:remove_old_aliases.rb - NEW customer_domain is: #{customer_domain}")

# skip in active (A/B update)
box = node[:workorder][:box][:ciAttributes]
if box.has_key?(:is_active) && box[:is_active] == 'false'
  Chef::Log.info('azuredns:remove_old_aliases.rb - skipping due to platform is_active false')
  return
end

cloud_service = node['workorder']['services']['dns'][cloud_name]
service_attrs = cloud_service['ciAttributes']

if service_attrs['cloud_dns_id'].nil? || service_attrs['cloud_dns_id'].empty?
  msg = "azuredns:remove_old_aliases.rb - no cloud_dns_id for dns cloud service: #{cloud_service['nsPath']} #{cloud_service['ciName']}"
  Chef::Log.error(msg)
  puts "***FAULT:FATAL=#{msg}"
  e = Exception.new('no backtrace')
  e.set_backtrace('')
  raise e
end

# entries Array of {name:String, values:Array}
entries = Array.new
aliases = Array.new
current_aliases = Array.new
full_aliases = Array.new
current_full_aliases = Array.new

# this is a check to see if it is a hostname payload instead of fqdn
# we don't want to remove the aliases for fqdn if it is a hostname payload
is_hostname_entry = false
if !node.workorder.payLoad.has_key?('Entrypoint')
  is_hostname_entry = true
end

if node.workorder.rfcCi.ciBaseAttributes.has_key?("aliases") && !is_hostname_entry
  begin
   aliases = JSON.parse(node.workorder.rfcCi.ciBaseAttributes.aliases)
  rescue Exception =>e
    Chef::Log.info("azuredns:remove_old_aliases.rb - could not parse aliases json: "+node.workorder.rfcCi.ciBaseAttributes.aliases)
  end
end

if node.workorder.rfcCi.ciAttributes.has_key?("aliases") && !is_hostname_entry
  begin
    current_aliases = JSON.parse(node.workorder.rfcCi.ciAttributes.aliases)
  rescue Exception =>e
    Chef::Log.info("azuredns:remove_old_aliases.rb - could not parse aliases json: "+node.workorder.rfcCi.ciAttributes.aliases)
  end
end

# if I don't have any previous aliases, no need to remove the current aliases from the list to delete.
if !aliases.nil?
  if !current_aliases.nil?
    current_aliases.each do |active_alias|
      aliases.delete(active_alias)
    end
  end
end

if node.workorder.rfcCi.ciBaseAttributes.has_key?("full_aliases") && !is_hostname_entry
  begin
   full_aliases = JSON.parse(node.workorder.rfcCi.ciBaseAttributes.full_aliases)
  rescue Exception =>e
    Chef::Log.info("azuredns:remove_old_aliases.rb - could not parse full_aliases json: "+node.workorder.rfcCi.ciBaseAttributes.full_aliases)
  end
end

if node.workorder.rfcCi.ciAttributes.has_key?("full_aliases") && !is_hostname_entry
  begin
    current_full_aliases = JSON.parse(node.workorder.rfcCi.ciAttributes.full_aliases)
  rescue Exception =>e
    Chef::Log.info("azuredns:remove_old_aliases.rb - could not parse full_aliases json: "+node.workorder.rfcCi.ciAttributes.full_aliases)
  end
end

# if I don't have any previous aliases, no need to remove the current aliases from the list to delete.
if !full_aliases.nil?
  if !current_full_aliases.nil?
    current_full_aliases.each do |active_full_alias|
      full_aliases.delete(active_full_alias)
    end
  end
end

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'

# get the azure token for making rest api calls to azure
include_recipe 'azuredns::get_azure_token'

recordset = AzureDns::RecordSet.new(service_attrs, node['azure_rest_token'], node['platform-resource-group'])

if !aliases.nil?
  # cloud-level short aliases
  aliases.each do |a|
    next if a.empty?
    alias_name = a + customer_domain
    Chef::Log.info("azuredns:remove_old_aliases.rb - alias_name is: #{alias_name}")

    # get the value from azure
    value = recordset.get_existing_records_for_recordset('CNAME', alias_name)

    if !value.nil?
      Chef::Log.info("azuredns:remove_old_aliases.rb - short alias dns_name: #{alias_name} value: #{value.first}")
      entries.push({:name => alias_name, :values => value.first })
      # deletable_entries.push({:name => alias_name, :values => value.first })
    else
      Chef::Log.info("azuredns:remove_old_aliases.rb - Nothing to remove")
    end

    if node.workorder.cloud.ciAttributes.priority == '1'

      alias_platform_dns_name = alias_name.gsub("\."+service_attrs['cloud_dns_id'],'').downcase
      Chef::Log.info("azuredns:remove_old_aliases.rb - alias_platform_dns_name is: #{alias_platform_dns_name}")
      # get the value from azure
      value = recordset.get_existing_records_for_recordset('CNAME', alias_platform_dns_name)
      if !value.nil?
        entries.push({:name => alias_platform_dns_name, :values => value.first })
      else
        Chef::Log.info('azuredns:remove_old_aliases.rb - Nothing to remove')
      end

    end
  end
end

if !full_aliases.nil?
  full_aliases.each do |full|
    # only cleaning up old CNAME aliases
    full_value = recordset.get_existing_records_for_recordset('CNAME', full)

    Chef::Log.info("azuredns:remove_old_aliases.rb - full alias dns_name: #{full} values: #{full_value.first}")
    entries.push({:name => full, :values => full_value.first })
    # deletable_entries.push({:name => full, :values => full_value})
  end
end

Chef::Log.info("azuredns:remove_old_aliases.rb - entries to remove are: #{entries}")

if !entries.nil?
  # for each entry, remove the record set from azure
  entries.each do |entry|
    name = entry[:name]
    Chef::Log.info("azuredns:remove_old_aliases.rb - removing entry: #{name}")
    recordset.remove_record_set(name, 'CNAME')
    Chef::Log.info('azuredns:remove_old_aliases.rb - entry removed')
  end
end
