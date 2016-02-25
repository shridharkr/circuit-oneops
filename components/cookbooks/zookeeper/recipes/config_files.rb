#
# Cookbook Name::       zookeeper
# Description::         Config files -- include this last after discovery
# Recipe::              config_files
# Author::              Chris Howe - Infochimps, Inc
#
# Copyright 2010, Infochimps, Inc.
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
#

#
# Config files
#
#zookeeper_hosts = discover_all(:zookeeper, :server).sort_by{|cp| cp.node[:facet_index] }.map(&:private_ip)

# use explicit value if set, otherwise make the leader a server iff there are
# four or more zookeepers kicking around
nodes = node.workorder.payLoad.RequiresComputes
zookeeper_hosts= Array.new 
nodes.each do |n|
   zookeeper_hosts.push(n[:ciAttributes][:dns_record])
  end

leader_is_also_server = node[:zookeeper][:leader_is_also_server]
if (leader_is_also_server.to_s == 'auto')
  leader_is_also_server = (zookeeper_hosts.length >= 4)
end
# So that node IDs are stable, use the server's index (eg 'foo-bar-3' = zk id 3)
# If zookeeper servers span facets, give each a well-sized offset in facet_role
# # (if 'bink' nodes have zkid_offset 10, 'foo-bink-7' would get zkid 17)
# node[:zookeeper][:zkid]  = node[:facet_index]
# node[:zookeeper][:zkid] += node[:zookeeper][:zkid_offset].to_i if node[:zookeeper][:zkid_offset]

# id_determined=node.workorder.rfcCi.ciName.split("-").last

id_determined=zookeeper_hosts.index(node[:ipaddress])

template_variables = {
  :zookeeper         => node[:zookeeper],
  :zookeeper_hosts   => zookeeper_hosts,
  :myid              => id_determined,
}


template "/var/zookeeper/data/myid" do
  owner         "zookeeper"
  mode          "0644"
  variables     template_variables
  source        "myid.erb"
end

template "#{node[:zookeeper][:home_dir]}/zookeeper-#{node[:zookeeper][:version]}/bin/zkEnv.sh" do
  owner         "zookeeper"
  mode          "0644"
  variables     template_variables
  source        "zkEnv.sh.erb"
end

template "/etc/init.d/zookeeper-server" do
  source "zookeeper-server.erb"
  owner "root"
  group "root"
  mode  "0755"
 variables     template_variables

end

