# Cookbook Name:: lb
# Recipe:: default
#
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


require 'fog'

# number retries for backend calls
max_retry_count = 5

env_name = node.workorder.payLoad["Environment"][0]["ciName"]
cloud_name = node.workorder.cloud.ciName

cloud_service = nil
if !node.workorder.services["lb"].nil? &&
  !node.workorder.services["lb"][cloud_name].nil?

  cloud_service = node.workorder.services["lb"][cloud_name]
end

if cloud_service.nil?
  Chef::Log.error("no cloud service defined. services: "+node.workorder.services.inspect)
  exit 1
end

include_recipe "lb::build_load_balancers"
lb_name = node[:lb_name]


instances = Array.new
computes = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Compute/ }
computes.each do |compute|
  instance_id = compute["ciAttributes"]["instance_id"]
  instances.push(instance_id)
end

# nsPath":"/xcom/demo/r-aws-1/bom"
security_group_parts = node.workorder.rfcCi.nsPath.split("/")
security_group = security_group_parts[3]+'.'+security_group_parts[2]+'.'+security_group_parts[1]
Chef::Log.info("security_group: "+security_group)


lb_dns_name = ""
Chef::Log.info("Cloud Service: #{cloud_service[:ciClassName]}")
# if ServiceBy exists then run the remote lb::add recipe
case cloud_service[:ciClassName].split(".").last.downcase
when /azure_lb/

  include_recipe "azure_lb::add"
  lb_dns_name = node.azurelb_ip

when /netscaler/

  # clear connection for replace (delete+add)
  node.set["ns_conn"] = nil
  n = netscaler_connection "conn" do
    action :nothing
  end
  n.run_action(:create)
  
  include_recipe "netscaler::stonith"                
  include_recipe "netscaler::add_server"
  include_recipe "netscaler::add_lbvserver"
  include_recipe "netscaler::add_servicegroup"  
  include_recipe "netscaler::logout"
  lb_dns_name = node.ns_lbvserver_ip  
  
when /rackspace/

  include_recipe "rackspace::add_lb"
  lb_dns_name = node.virtual_ip 
  
when /haproxy/

  lb_dns_name = "haproxy."+node.customer_domain;
  
  # gen /opt/oneops/pool_#{lb_ci_id} with: 
  # server #{ciName} #{compute_ip}:#{port} cookie #{ciName} weight 1 check inter 2000 rise 2 fall 5
  # the vservice will put them together

  pool_rows = ""
  depends_on.each do |instance|
    ip = instance["ciAttributes"]["private_ip"]
    ciName = instance["ciName"]
    # iport will get eval'd by the vservice
    pool_rows += "server #{ciName} #{ip}:"+'#{iport} '+"cookie #{ciName} weight 1 check inter 2000 rise 2 fall 5\n"
  end
  
  #
  pool_file = "/opt/oneops/pool_#{lb_name}"      
  File.open(pool_file, 'w') {|f| f.write(pool_rows) }

when /neutron/
  include_recipe "neutron::add_lb"
  lb_dns_name = node.lb_dns_name
      
when /elb/

  include_recipe "elb::add_lb"
  lb_dns_name = node.lb_dns_name
          
end

if lb_dns_name.nil? || lb_dns_name.empty?
  Chef::Log.error("prevent empty dns_record - fail")
  exit 1
end

puts "***RESULT:dns_record=#{lb_dns_name}"
