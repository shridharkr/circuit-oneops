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

require 'excon'

def wait_for_lb_state(conn,lb_name)
  ok = false
  # wait for ok
  while !ok do

    lbs = JSON.parse(conn.request(:method => :get,
    :path => "/v2.0/lbaas/loadbalancers.json?fields=id&name=#{lb_name}").body)["loadbalancers"]

    if lbs.size < 1
      Chef::Log.error("no lb: #{lb_name}")
      exit 1
    else
      lb = lbs.first
      Chef::Log.info("lb provisioning_status: #{lb['provisioning_status']}")
      if lb['provisioning_status'] == "ACTIVE"
        Chef::Log.info("active")
        ok = true
      else
        Chef::Log.info("sleeping 30")
        sleep 30
      end

    end
  end
end

cloud_name = node.workorder.cloud.ciName
cloud_service = node[:workorder][:services][:lb][cloud_name]
instances = Array.new
computes = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Compute/ }
computes.each do |compute|
  instance_id = compute["ciAttributes"]["instance_id"]
  instances.push(instance_id)
end

cloud_name = node[:workorder][:cloud][:ciName]
service = node[:workorder][:services][:lb][cloud_name][:ciAttributes]

user = {"username" => service[:username],
        "password" => service[:password]}

auth_req = {"auth" => {"tenantName" => service[:tenant],
                       "passwordCredentials" => user}}

host = service[:endpoint].gsub("/v2.0/tokens","")
Chef::Log.info("endpoint: #{host}")
conn = Excon.new(host, :ssl_verify_peer => false)
resp = conn.request(:method=>:post, :path=> '/v2.0/tokens', :body => JSON.dump(auth_req))
auth_token = JSON.parse(resp.body)['access']['token']['id']

conn = Excon.new(service[:endpoint].gsub(":5000/v2.0/tokens",":9696"),
  :ssl_verify_peer => false,
  :headers => {
    'Content-Type' => 'application/json',
    'Accept'       => 'application/json',
    'X-Auth-Token' => auth_token
   })

node.loadbalancers.each do |lb_def|

  lb_name = lb_def[:name]
  iport = lb_def[:iport]
  Chef::Log.info("lb name: "+lb_name)

  # loadbalancer
  lb = nil
  subnet = JSON.parse(conn.request(:method => :get,
    :path => "/v2.0/subnets.json?fields=id&name=private-subnet").body)["subnets"].first

  lbs = JSON.parse(conn.request(:method => :get,
    :path => "/v2.0/lbaas/loadbalancers.json?fields=id&name=#{lb_name}").body)["loadbalancers"]
  if lbs.size < 1
    req = {:loadbalancer => {:name => lb_name, :vip_subnet_id => subnet['id'], :admin_state_up => true}}
    lb = JSON.parse(conn.request(:method => :post,
            :path => "/v2.0/lbaas/loadbalancers.json", :body => JSON.dump(req)).body)['loadbalancer']
    puts "new lb: #{lb.inspect}"
  else
    lb = lbs.first
    puts "existing lb: #{lb.inspect}"
  end

  wait_for_lb_state(conn,lb_name)

  # listener
  listener = nil
  listener_name = lb_name.gsub(/-lb$/,"-listener")
  listeners = JSON.parse(conn.request(:method => :get,
    :path => "/v2.0/lbaas/listeners.json?fields=id&name=#{listener_name}").body)["listeners"]
  if listeners.size < 1
    req = {:listener => {:name => listener_name, :protocol_port => lb_def[:vport].to_i,
              :protocol => lb_def[:vprotocol].upcase, :loadbalancer_id => lb['id'], :admin_state_up => true}}
    listener = JSON.parse(conn.request(:method => :post,
            :path => "/v2.0/lbaas/listeners.json", :body => JSON.dump(req)).body)['listener']
    if listener.nil?
      sleep 10

      listener = JSON.parse(conn.request(:method => :get,
        :path => "/v2.0/lbaas/listeners.json?fields=id&name=#{listener_name}").body)["listeners"].first

      if listener.nil?
         puts "cannot get new listener: #{listener_name}"
         exit 1
      end

    end

    puts "new listener: #{listener.inspect}"
  else
    listener = listeners.first
    puts "existing listener: #{listener.inspect}"
  end

  wait_for_lb_state(conn,lb_name)
  
  # pool
  pool = nil
  pool_name = lb_name.gsub(/-lb$/,"-pool")
  lb_method = "ROUND_ROBIN"
  
  case node.workorder.rfcCi.ciAttribute.lbmethod
  when "roundrobin"
    lb_method = "ROUND_ROBIN"
  when "leastconn"
    lb_method = "LEAST_CONNECTIONS"      
  end
  iprotocol = lb_def[:iprotocol].upcase
    
  pools = JSON.parse(conn.request(:method => :get,
    :path => "/v2.0/lbaas/pools.json?fields=id&name=#{pool_name}").body)["pools"]
  if pools.size < 1
    req = {:pool => {:name => pool_name, :lb_algorithm => lb_method, :listener_id => listener['id'],
                     :protocol => iprotocol, :admin_state_up => true}}

    pool = JSON.parse(conn.request(:method => :post,
            :path => "/v2.0/lbaas/pools.json", :body => JSON.dump(req)).body)['pool']

    if pool.nil?
      sleep 10
      pool = JSON.parse(conn.request(:method => :get,
        :path => "/v2.0/lbaas/pools.json?fields=id&name=#{pool_name}").body)["pools"].first
      if pool.nil?
         puts "cannot get new pool: #{pool_name}"
         exit 1
      end
    end

    puts "new pool: #{pool.inspect}"
  else
    pool = pools.first
    puts "existing pool: #{pool.inspect}"
  end

  wait_for_lb_state(conn,lb_name)

  # members
  members_resp = JSON.parse(conn.request(:method => :get,
    :path => "/v2.0/lbaas/pools/#{pool['id']}/members.json").body)

  members = []
  if members_resp.has_key?("members")
     members = members_resp["members"]
  end

  Chef::Log.info("members_resp: #{members_resp.inspect}")

  lb_full = JSON.parse(conn.request(:method => :get,
    :path => "/v2.0/lbaas/loadbalancers.json?id=#{lb['id']}").body)["loadbalancers"].first

  stale_members = []
  if !members.nil?
    stale_members = members.clone
  end

  computes.each do |c|
    is_missing = true
    ip = c['ciAttributes']['private_ip']

    member = nil
    members.each do |m|
      if m['address'] == ip
         # not stale
         is_missing = false
         member = m
      end
    end

    if is_missing
      req = {:member => {:address => ip, :protocol_port => iport, :name => ip+":"+iport,
       :subnet_id => subnet['id'],  :admin_state_up => true}}

      member_name = ip+":"+iport
      member = JSON.parse(conn.request(:method => :post, :name => member_name,
              :path => "/v2.0/lbaas/pools/#{pool['id']}/members.json", :body => JSON.dump(req)).body)["member"]

      if member.nil?
        sleep 10
        member = JSON.parse(conn.request(:method => :get, :name => member_name,
              :path => "/v2.0/lbaas/pools/#{pool['id']}/members.json?name=#{member_name}", :body => JSON.dump(req)).body)["members"].first
        if member.nil?
          puts "cannot get new member: /v2.0/lbaas/pools/#{pool['id']}/members.json?name=#{member_name} "
        end
      end

      puts "new member: #{member.inspect}"
    else
      puts "existing member: #{member.inspect}"
    end
  end

  node.set["lb_dns_name"] = lb_full["vip_address"]

end  