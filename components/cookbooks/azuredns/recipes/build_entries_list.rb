# Cookbook Name:: azuredns
# Recipe:: build_entries_list
#
# Copyright 2014, OneOps
#
# All rights reserved - Do Not Redistribute
#
# builds a list of dns entries based on entrypoint, aliases, cloud and platform
# no ManagedVia - recipes will run on the gw

require 'json'

cloud_name = node['workorder']['cloud']['ciName']
domain_name = node['workorder']['services']['dns'][cloud_name]['ciAttributes']['zone']

# set to empty set to handle delete on inactive platform
node.set['entries'] = []

# get dns value using dns_record attr or if empty resort to case stmt based on component class
def get_dns_values (components)
  values = Array.new
  components.each do |component|

    attrs = component['ciAttributes']

    dns_record = attrs['dns_record'] || ''

    # backwards compliance: until all computes,lbs,clusters have dns_record populated need to get via case stmt
    if dns_record.empty?
      case component['ciClassName']
      when /Compute/
        if attrs.has_key?('public_dns') && !attrs['public_dns'].empty?
         dns_record = attrs['public_dns']+'.'
        else
         dns_record = attrs['public_ip']
        end

        if location == '.int' || dns_entry == nil || dns_entry.empty?
          dns_record = attrs['private_ip']
        end

      when /Lb/
        dns_record = attrs['dns_record']
      when /Cluster/
        dns_record = attrs['shared_ip']
      end
    else
      # unless ends w/ . or is an ip address
      dns_record += '.' unless dns_record =~ /,|\.$|^\d+\.\d+\.\d+\.\d+$/
    end

    if dns_record.empty?
      Chef::Log.error('azuredns:build_entries_list.rb - cannot get dns_record value for: '+component.inspect)
      exit 1
    end

    if dns_record =~ /,/
      values.concat dns_record.split(',')
    else
      values.push(dns_record)
    end
  end
  return values
end

# ex) customer_domain: env.asm.org.oneops.com
customer_domain = node.customer_domain
if node.customer_domain !~ /^\./
  customer_domain = '.'+node.customer_domain
end
Chef::Log.info("azuredns:build_entries_list.rb - customer_domain is: #{customer_domain}")

# remove the zone name from the customer domain for azure.
customer_domain = customer_domain.gsub('.'+domain_name, '')
Chef::Log.info("azuredns:build_entries_list.rb - NEW customer_domain is: #{customer_domain}")

# skip in active (A/B update)
box = node[:workorder][:box][:ciAttributes]
if box.has_key?(:is_active) && box[:is_active] == 'false'
  Chef::Log.info('azuredns:build_entries_list.rb - skipping due to platform is_active false')
  return
end

# entries Array of {name:String, values:Array}
entries = Array.new

# build set of entries from entrypoint or DependsOn compute
ci = nil

# used to prevent full,short aliases on hostname entries
is_hostname_entry = false
if node.workorder.payLoad.has_key?('Entrypoint')
  ci = node.workorder.payLoad.Entrypoint[0]
  dns_name = (ci['ciName'] +customer_domain).downcase

else
  computes = node.workorder.payLoad.DependsOn.select { |d| d['ciClassName'] =~ /Compute/ }

  # if the computes is empty or it doesn't have the hostname, get the other computes.
  if computes.empty?
   computes = node.workorder.payLoad.DependsOn.select { |d| d['ciClassName'] =~ /Os/ }
  end

  if computes.size > 1
    Chef::Log.error('azuredns:build_entries_list.rb - unsupported usecase - need to check why there are multiple computes for same fqdn')
    e = Exception.new('no backtrace')
    e.set_backtrace('')
    raise e
  end
  is_hostname_entry = true
  ci = computes.first
  hostname = ci['ciAttributes']['hostname']
  if hostname.nil?
    # check the other
    computes = node.workorder.payLoad.DependsOn.select { |d| d['ciClassName'] =~ /Os/ }
    ci = computes.first
    hostname = ci['ciAttributes']['hostname']
  end
  dns_name = (hostname + customer_domain).downcase

end

# short aliases which will use the customer/env domain
aliases = Array.new
if node.workorder.rfcCi.ciAttributes.has_key?('aliases') && !is_hostname_entry
  begin
    aliases = JSON.parse(node.workorder.rfcCi.ciAttributes.aliases)
  rescue Exception =>e
    Chef::Log.info('could not parse aliases json: '+node.workorder.rfcCi.ciAttributes.aliases)
  end
end

# full aliases uses as-is, cnamed to the platform entry
full_aliases = Array.new
if node.workorder.rfcCi.ciAttributes.has_key?('full_aliases') && !is_hostname_entry
  begin
    full_aliases = JSON.parse(node.workorder.rfcCi.ciAttributes.full_aliases)
  rescue Exception =>e
    Chef::Log.info('could not parse full_aliases json: '+node.workorder.rfcCi.ciAttributes.full_aliases)
  end
end

cloud_service = node['workorder']['services']['dns'][cloud_name]
service_attrs = cloud_service['ciAttributes']
if service_attrs['cloud_dns_id'].nil? || service_attrs['cloud_dns_id'].empty?
  msg = "azuredns:build_entries_list.rb - no cloud_dns_id for dns cloud service: #{cloud_service['nsPath']} #{cloud_service['ciName']}"
  Chef::Log.error(msg)
  puts "***FAULT:FATAL=#{msg}"
  e = Exception.new('no backtrace')
  e.set_backtrace('')
  raise e
end

if !node.workorder.payLoad.has_key?('DependsOn')
  msg = 'azuredns:build_entries_list.rb - missing DependsOn payload'
  Chef::Log.error(msg)
  puts "***FAULT:FATAL=#{msg}"
  e = Exception.new('no backtrace')
  e.set_backtrace('')
  raise e
end

# values using DependsOn's dns_record attr
deps = node.workorder.payLoad['DependsOn'].select { |d| d['ciAttributes'].has_key? 'dns_record' }
values = get_dns_values(deps)

# cloud-level add entry - will loop thru and cleanup & create them later
entries.push({:name => dns_name, :values => values })
Chef::Log.info("azuredns:build_entries_list.rb - cloud level dns: #{dns_name} values: "+values.to_s)
deletable_entries = [{:name => dns_name, :values => values }]

# cloud-level short aliases
aliases.each do |a|
  next if a.empty?
  alias_name = a + customer_domain
  Chef::Log.info("azuredns:build_entries_list.rb - short alias dns_name: #{alias_name} values: "+dns_name)
  entries.push({:name => alias_name, :values => dns_name })
  deletable_entries.push({:name => alias_name, :values => dns_name })
end

# platform-level remove cloud_dns_id for primary entry
primary_platform_dns_name = dns_name.gsub("\."+service_attrs['cloud_dns_id'],'').downcase

Chef::Log.info("azuredns:build_entries_list.rb - primary_platform_dns_name is: #{primary_platform_dns_name}")

if node.workorder.rfcCi.ciAttributes.has_key?('ptr_enabled') && node.workorder.rfcCi.ciAttributes.ptr_enabled == 'true'
  Chef::Log.info('azuredns:build_entries_list.rb - PTR Records are configured automatically in Azure DNS, ignoring')
end

 # platform level
if node.workorder.cloud.ciAttributes.priority == '1'

  if node.has_key?('gslb_domain') && !node.gslb_domain.nil?
    value_array = node.gslb_domain
  else
    value_array = []
    if values.class.to_s == 'String'
      value_array.push(values)
    else
      value_array += values
    end

  end

  if node.dns_action != 'delete' || (node.dns_action == 'delete' && node.is_last_active_cloud_in_dc)
    entries.push({:name => primary_platform_dns_name, :values => value_array })
    deletable_entries.push({:name => primary_platform_dns_name, :values => value_array })
    Chef::Log.info("azuredns:build_entries_list.rb - primary platform dns: #{primary_platform_dns_name} values: "+value_array.inspect)
  else
    Chef::Log.info("azuredns:build_entries_list.rb - not deleting #{primary_platform_dns_name} because its not the last one")
  end

  aliases.each do |a|
    next if a.empty?
    next if node.dns_action == 'delete' && !node.is_last_active_cloud
    # skip if user has a short alias same as platform name
    next if a == node.workorder.box.ciName

    alias_name = a  + customer_domain
    alias_platform_dns_name = alias_name.gsub("\."+service_attrs['cloud_dns_id'],'').downcase
    Chef::Log.info("azuredns:build_entries_list.rb - alias_name is: #{alias_name}")
    Chef::Log.info("azuredns:build_entries_list.rb - alias_platform_dns_name is: #{alias_platform_dns_name}")

    if node.has_key?('gslb_domain') && !node.gslb_domain.nil?
      primary_platform_dns_name = node.gslb_domain
    end

    Chef::Log.info("azuredns:build_entries_list.rb - alias dns_name: #{alias_platform_dns_name} values: "+primary_platform_dns_name)
    entries.push({:name => alias_platform_dns_name, :values => primary_platform_dns_name })
    deletable_entries.push({:name => alias_platform_dns_name, :values => primary_platform_dns_name })
  end

  full_aliases.each do |full|
    next if node.dns_action == 'delete' && !node.is_last_active_cloud

    full_value = primary_platform_dns_name
    if node.has_key?('gslb_domain') && !node.gslb_domain.nil?
      full_value = node.gslb_domain
    end

    Chef::Log.info("azuredns:build_entries_list.rb - full alias dns_name: #{full} values: "+full_value)
    entries.push({:name => full, :values => full_value })
    deletable_entries.push({:name => full, :values => full_value})
  end

end

if node.has_key?('dc_entry')
  if node.dns_action != 'delete' ||
    (node.dns_action == 'delete' && node.is_last_active_cloud_in_dc)

    entries.push(node.dc_entry)
    deletable_entries.push(node.dc_entry)
  end
end

entries_hash = {}
entries.each do |entry|
  key = entry[:name]
  entries_hash[key] = entry[:values]
end
puts "***RESULT:entries=#{JSON.dump(entries_hash)}"

# pass to set_dns_entries
node.set[:entries] = entries
# needed due to cleanup/delete logic using dns call to get list
node.set[:deletable_entries] = deletable_entries
