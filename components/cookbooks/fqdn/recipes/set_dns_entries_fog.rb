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
# Recipe:: set_dns_entries
#
# uses node[:entries] list of dns entries based on entrypoint, aliases, zone, and platform to update dns
# no ManagedVia - recipes will run on the gw

# get dns record type - check for ip addresses
def get_record_type (dns_values)
  record_type = "CNAME"
  ips = dns_values.grep(/\d+\.\d+\.\d+\.\d+/)
  if ips.size > 0
    record_type = "A"
  end     
  return record_type
end

# set in get_fog_connection  
zone = node.fog_zone
ns = node.ns

#
# delete / create dns entries
#
node[:entries].each do |entry|
  dns_match = false
  dns_type = get_record_type(entry[:values]) 
  dns_name = entry[:name]
  dns_values = entry[:values]
  
  existing_dns = `dig +short #{dns_name} @#{ns}`.split("\n")
  
  existing_ips = existing_dns.grep(/\d+\.\d+\.\d+\.\d+/)
  if dns_type == "CNAME" && existing_ips.size > 0 && existing_dns.size >1
    existing_ips.each do |ip|
       existing_dns.delete(ip)      
    end
  end
  
  existing_comparison = existing_dns.sort <=> dns_values.sort
  Chef::Log.info("new values:"+dns_values.sort.to_s)  
  Chef::Log.info("existing:"+existing_dns.sort.to_s)
    
  if existing_dns.length > 0 && (existing_comparison != 0 || node[:dns_action] == "delete")
    delete_type = get_record_type(existing_dns)
    Chef::Log.info("delete #{delete_type}: #{dns_name} to #{existing_dns.to_s}") 

    # rackspace get is by record_id, not name and type like route53    
    if node.dns_service_class =~ /rackspace/
      record = zone.records.all.select{ |r| r.name == dns_name.downcase}.first
    else
      record = zone.records.get(dns_name, delete_type)            
    end    
    if record == nil
      # downcase is needed because it will create a dns entry w/ CamelCase, but doesn't match on the get
      if node.dns_service_class =~ /rackspace/
        record = zone.records.all.select{ |r| r.name == dns_name.downcase}.first
      else
        record = zone.records.get(dns_name, delete_type)            
      end    
      if record == nil
        Chef::Log.error("could not get record")
        exit 1
      end
    end
    record.destroy
  else
    if existing_dns.length > 0
      dns_match = true
    end
  end
  
  # delete workorder skips the create call
  if node[:dns_action] == "delete"
    next
  end
  
  if dns_match
    Chef::Log.info("exists #{dns_type}: #{dns_name} to #{dns_values.to_s}") 
  else
    ttl = 60
    if node.workorder.rfcCi.ciAttributes.has_key?("ttl")
      ttl = node.workorder.rfcCi.ciAttributes.ttl.to_i
    end
    if node.dns_service_class =~ /rackspace/ && ttl < 300
      Chef::Log.warn("rackspace dns has min ttl of 300 - using that")
      ttl = 300
    end
        
    Chef::Log.info("create #{dns_type}: #{dns_name} to #{dns_values.to_s}")
    if node.dns_service_class =~ /rackspace/

      # rackspace cannot handle array dns_value      
      dns_values.each do |dns_value|
        begin
          record = zone.records.create(
           :value => dns_value,
           :name  => dns_name,
           :type  => dns_type,
           :ttl => ttl
          )
         rescue Fog::DNS::Rackspace::CallbackError => e
           puts "#{e.details}"
           next if e.details =~ /duplicate/
           raise e
         end
      end

    else
      record = zone.records.create(
        :value => dns_values,
        :name  => dns_name,
        :type  => dns_type,
        :ttl => ttl
      )      
    end
    
    # lets verify using authoratative dns sever
    sleep 5    
    verified = false
    max_retry_count = 30
    retry_count = 0
    while !verified && retry_count<max_retry_count do
      existing_dns = `dig +short #{dns_name} @#{ns}`.split("\n")

      existing_comparison = existing_dns.sort <=> dns_values.sort
      Chef::Log.info("verify ns has: "+dns_values.sort.to_s)  
      Chef::Log.info("ns #{ns} has: "+existing_dns.sort.to_s)
      if existing_comparison == 0
        verified = true
        Chef::Log.info("verified.")
      else 
        Chef::Log.info("waiting 10sec for #{ns} to get updated...")
        sleep 10
      end
      retry_count +=1
    end
    
    if verified == false
      Chef::Log.info("dns could not be verified after 5min!")    
      exit 1
    end
    
  end
end
