# Copyright 2016, Walmart Stores, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Cookbook Name:: fqdn
# Recipe:: build_entries_list
#
# builds a list of dns entries based on entrypoint, aliases, cloud and platform
# no ManagedVia - recipes will run on the gw

require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
domain_name = node[:workorder][:services][:dns][cloud_name][:ciAttributes][:zone]

# set to empty set to handle delete on inactive platform
node.set["entries"] = []

# get dns value using dns_record attr or if empty resort to case stmt based on component class
def get_dns_values (components)
  values = Array.new
  components.each do |component|

    attrs = component[:ciAttributes]

    dns_record = attrs[:dns_record] || ''

    # backwards compliance: until all computes,lbs,clusters have dns_record populated need to get via case stmt
    if dns_record.empty?
      case component[:ciClassName]
      when /Compute/
        if attrs.has_key?("public_dns") && !attrs[:public_dns].empty?
         dns_record = attrs[:public_dns]+'.'
        else
         dns_record = attrs[:public_ip]
        end

        if location == ".int" || dns_entry == nil || dns_entry.empty?
          dns_record = attrs[:private_ip]
        end

      when /Lb/
        dns_record = attrs[:dns_record]
      when /Cluster/
        dns_record = attrs[:shared_ip]
      end
    else
      # unless ends w/ . or is an ip address
      dns_record += '.' unless dns_record =~ /,|\.$|^\d+\.\d+\.\d+\.\d+$/
    end

    if dns_record.empty?
      Chef::Log.error("cannot get dns_record value for: "+component.inspect)
      exit 1
    end

    if dns_record =~ /,/
      values.concat dns_record.split(",")
    else
      values.push(dns_record)
    end
  end
  return values
end


def get_primary_ips(ci,values,customer_domain,ns)

  other_active_clouds = []
  if node.workorder.payLoad.has_key?("activeclouds")
     node.workorder.payLoad.activeclouds.each do |cloud|
       if cloud["nsPath"] != node.workorder.cloud.nsPath
         other_active_clouds.push(cloud["nsPath"])
       end
     end

    # map by ns_path
    dns_cloud_map = {}
    if node.workorder.payLoad.has_key?("remotedns")
      node.workorder.payLoad.remotedns.each do |dns_service|
        ns_path = dns_service["nsPath"]
        dns_cloud_map[ns_path] = dns_service["ciAttributes"]
      end

    end

    cloud_level_name = ci[:ciName] + customer_domain
    cloud_name = node.workorder.cloud.ciName
    cloud_dns_service = node[:workorder][:services][:dns][cloud_name][:ciAttributes]
    cloud_dns_zone = cloud_dns_service[:zone]
    cloud_dns_id = cloud_dns_service[:cloud_dns_id]

    # foreach other active cloud get the cloud-level entry and ip for the RR dns entry
    other_active_clouds.each do |cloud|
      ci_name = cloud.split("/").last
      next if ci_name == cloud_name
      other_cloud_service = dns_cloud_map[cloud]
      other_cloud_dns_id =  other_cloud_service["cloud_dns_id"]
      other_cloud_dns_zone =  other_cloud_service["zone"]
      other_cloud_dns_name =   cloud_level_name.gsub(
           "\."+cloud_dns_id+"\."+cloud_dns_zone,
           "."+other_cloud_dns_id+"."+other_cloud_dns_zone).downcase
      Chef::Log.info("other_cloud_dns_name: dig +short #{other_cloud_dns_name} @#{ns}")
      other_ips = `dig +short #{other_cloud_dns_name} @#{ns} | grep -v ";;"`.split("\n")
      other_ips.each do |rr_entry|
        Chef::Log.info("#{other_cloud_dns_name} #{rr_entry}")
        values.push(rr_entry) if !values.include?(rr_entry)
      end
    end

  end

  return values
end

# ex) customer_domain: env.asm.org.oneops.com
customer_domain = node.customer_domain
if node.customer_domain !~ /^\./
  customer_domain = '.'+node.customer_domain
end

# skip in active (A/B update)
box = node[:workorder][:box][:ciAttributes]
if box.has_key?(:is_active) && box[:is_active] == "false"
  Chef::Log.info("skipping due to platform is_active false")
  return
end

# entries Array of {name:String, values:Array}
entries = Array.new

#
# build set of entries from entrypoint or DependsOn compute
#
ci = nil

# used to prevent full,short aliases on hostname entries
is_hostname_entry = false
if node.workorder.payLoad.has_key?("Entrypoint")
  ci = node.workorder.payLoad.Entrypoint[0]
  dns_name = (ci[:ciName] +customer_domain).downcase

else
  os = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Os/ }

  if os.size > 1
    Chef::Log.error("unsupported usecase - need to check why there are multiple os for same fqdn")
    e = Exception.new("no backtrace")
    e.set_backtrace("")
    raise e
  end
  is_hostname_entry = true
  ci = os.first
  dns_name = (ci[:ciAttributes][:hostname] + customer_domain).downcase

end


# short aliases which will use the customer/env domain
aliases = Array.new
if node.workorder.rfcCi.ciAttributes.has_key?("aliases") && !is_hostname_entry
  begin
    aliases = JSON.parse(node.workorder.rfcCi.ciAttributes.aliases)
  rescue Exception =>e
    Chef::Log.info("could not parse aliases json: "+node.workorder.rfcCi.ciAttributes.aliases)
  end
end

# full aliases uses as-is, cnamed to the platform entry
full_aliases = Array.new
if node.workorder.rfcCi.ciAttributes.has_key?("full_aliases") && !is_hostname_entry
  begin
    full_aliases = JSON.parse(node.workorder.rfcCi.ciAttributes.full_aliases)
  rescue Exception =>e
    Chef::Log.info("could not parse full_aliases json: "+node.workorder.rfcCi.ciAttributes.full_aliases)
  end
end

# get authoratative NS's and find one we can connect to
ns_list = `dig +short NS #{domain_name}`.split("\n")
ns = nil
ns_list.each do |n|
  `nc -w 2 #{n} 53`
  if $?.to_i == 0
    ns = n
    break
  else
    Chef::Log.info("cannot connect to ns: #{n} ...trying another")
  end
end

Chef::Log.info("authoritative_dns_server: "+ns.inspect)


cloud_service = node[:workorder][:services][:dns][cloud_name]
service_attrs = cloud_service[:ciAttributes]
if service_attrs[:cloud_dns_id].nil? || service_attrs[:cloud_dns_id].empty?
  msg = "no cloud_dns_id for dns cloud service: #{cloud_service[:nsPath]} #{cloud_service[:ciName]}"
  Chef::Log.error(msg)
  puts "***FAULT:FATAL=#{msg}"
  e = Exception.new("no backtrace")
  e.set_backtrace("")
  raise e
end


if !node.workorder.payLoad.has_key?(:DependsOn)
  msg = "missing DependsOn payload"
  Chef::Log.error(msg)
  puts "***FAULT:FATAL=#{msg}"
  e = Exception.new("no backtrace")
  e.set_backtrace("")
  raise e
end

# values using DependsOn's dns_record attr
deps = node.workorder.payLoad[:DependsOn].select { |d| d[:ciAttributes].has_key? "dns_record" }
values = get_dns_values(deps)

# cloud-level add entry - will loop thru and cleanup & create them later
entries.push({:name => dns_name, :values => values })
Chef::Log.info("cloud level dns: #{dns_name} values: "+values.to_s)
deletable_entries = [{:name => dns_name, :values => values }]


# cloud-level short aliases
aliases.each do |a|
  next if a.empty?
  alias_name = a + customer_domain
  Chef::Log.info("short alias dns_name: #{alias_name} values: "+dns_name)
  entries.push({:name => alias_name, :values => dns_name })
  deletable_entries.push({:name => alias_name, :values => dns_name })
end


# platform-level remove cloud_dns_id for primary entry
primary_platform_dns_name = dns_name.gsub("\."+service_attrs[:cloud_dns_id]+"\."+service_attrs[:zone],"."+service_attrs[:zone]).downcase


if node.workorder.rfcCi.ciAttributes.has_key?("ptr_enabled") &&
  node.workorder.rfcCi.ciAttributes.ptr_enabled == "true"

  ptr_value = dns_name
  if node.workorder.rfcCi.ciAttributes.ptr_source == "platform"
    ptr_value = primary_platform_dns_name
    if is_hostname_entry
      ptr_value = node.workorder.box.ciName
      ptr_value += customer_domain.gsub("\."+service_attrs[:cloud_dns_id]+"\."+service_attrs[:zone],"."+service_attrs[:zone])
    end
  end

  values.each do |ip|
    next unless ip =~ /^\d+\.\d+\.\d+\.\d+$/
    ptr = {:name => ip, :values => ptr_value.downcase}
    Chef::Log.info("ptr: #{ptr.inspect}")
    entries.push(ptr)
    deletable_entries.push(ptr)
  end
end


 # platform level
if node.workorder.cloud.ciAttributes.priority == "1"

  if node.has_key?("gslb_domain") && !node.gslb_domain.nil?
    value_array = node.gslb_domain
  else
    # infoblox doesnt support round-robin cnames so need to get other primary cloud-level ip's
    value_array = []
    if values.class.to_s == "String"
      value_array.push(values)
    else
      value_array += values
    end

    if node.dns_action != "delete" ||
      (node.dns_action == "delete" && node.is_last_active_cloud)

      get_primary_ips(ci,value_array,customer_domain,ns)

    end

  end

  if node.dns_action != "delete" ||
    (node.dns_action == "delete" && node.is_last_active_cloud_in_dc)

    entries.push({:name => primary_platform_dns_name, :values => value_array })
    deletable_entries.push({:name => primary_platform_dns_name, :values => value_array })
    Chef::Log.info("primary platform dns: #{primary_platform_dns_name} values: "+value_array.inspect)
  else
    Chef::Log.info("not deleting #{primary_platform_dns_name} because its not the last one")
  end


  aliases.each do |a|
    next if a.empty?
    next if node.dns_action == "delete" && !node.is_last_active_cloud
    # skip if user has a short alias same as platform name
    next if a == node.workorder.box.ciName

    alias_name = a  + customer_domain
    alias_platform_dns_name = alias_name.gsub("\."+service_attrs[:cloud_dns_id]+"\."+service_attrs[:zone],"."+service_attrs[:zone]).downcase

    if node.has_key?("gslb_domain") && !node.gslb_domain.nil?
      primary_platform_dns_name = node.gslb_domain
    end

    Chef::Log.info("alias dns_name: #{alias_platform_dns_name} values: "+primary_platform_dns_name)
    entries.push({:name => alias_platform_dns_name, :values => primary_platform_dns_name })
    deletable_entries.push({:name => alias_platform_dns_name, :values => primary_platform_dns_name })
  end

  full_aliases.each do |full|
    next if node.dns_action == "delete" && !node.is_last_active_cloud

    full_value = primary_platform_dns_name
    if node.has_key?("gslb_domain") && !node.gslb_domain.nil?
      full_value = node.gslb_domain
    end

    Chef::Log.info("full alias dns_name: #{full} values: "+full_value)
    entries.push({:name => full, :values => full_value })
    deletable_entries.push({:name => full, :values => full_value})
  end


end

if node.has_key?("dc_entry")
  if node.dns_action != "delete" ||
    (node.dns_action == "delete" && node.is_last_active_cloud_in_dc)

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
