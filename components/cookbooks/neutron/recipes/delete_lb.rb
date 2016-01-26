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
Chef::Log.info("host: #{host} auth_req: #{auth_req}")
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

  # pool
  pool = nil
  pool_name = lb_name.gsub(/-lb$/,"-pool")
  pools = JSON.parse(conn.request(:method => :get,
    :path => "/v2.0/lbaas/pools.json?fields=id&name=#{pool_name}").body)["pools"]
  if pools.size < 1
    puts "already deleted pool."
  else
    pool = pools.first
    resp = conn.request(:method => :delete, :path => "/v2.0/lbaas/pools/#{pool['id']}.json")
    puts "del pool resp: #{resp.inspect}"
  end

  sleep 10

  # listener
  listener = nil
  listener_name = lb_name.gsub(/-lb$/,"-listener")
  listeners = JSON.parse(conn.request(:method => :get,
    :path => "/v2.0/lbaas/listeners.json?fields=id&name=#{listener_name}").body)["listeners"]
  if listeners.size < 1
    puts "already deleted listener."
  else
    listener = listeners.first
    resp = conn.request(:method => :delete, :path => "/v2.0/lbaas/listeners/#{listener['id']}.json")
    puts "del listener resp: #{resp.inspect}"
  end

  sleep 10

  # loadbalancer
  lb = nil
  lbs = JSON.parse(conn.request(:method => :get,
    :path => "/v2.0/lbaas/loadbalancers.json?fields=id&name=#{lb_name}").body)["loadbalancers"]
  if lbs.size < 1
    puts "already deleted lb."
  else
    lb = lbs.first
    resp = conn.request(:method => :delete, :path => "/v2.0/lbaas/loadbalancers/#{lb['id']}.json")
    puts "del loadbalancer resp: #{resp.inspect}"
  end

end