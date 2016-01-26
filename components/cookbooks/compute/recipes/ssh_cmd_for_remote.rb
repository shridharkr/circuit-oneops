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

#
# builds ssh cmd for remote compute cmd
#

unless node.workorder.payLoad.has_key? "SecuredBy"
  Chef::Log.error("unsupported, missing SecuredBy")
  return false
end

include_recipe "compute::get_ip_from_ci"

# tmp file to store private key
puuid = (0..32).to_a.map{|a| rand(32).to_s(32)}.join
ssh_key_file = "/tmp/"+puuid

file ssh_key_file do
  content node.workorder.payLoad[:SecuredBy][0][:ciAttributes][:private]
  mode 0600
end

user = "root"
if node.has_key?("use_initial_user") && node.use_initial_user == true && 
   !node.initial_user.nil? && node.initial_user != "unset"
  user = node.initial_user
end

ssh_options = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

if node.ip.nil?
  ip = "IP"
else
  ip = node.ip
end

node.set[:ssh_key_file] = ssh_key_file
node.set[:ssh_cmd] = "ssh -i #{ssh_key_file} #{ssh_options} #{user}@#{ip} "
node.set[:ssh_interactive_cmd] = "ssh -t -t -i #{ssh_key_file} #{ssh_options} #{user}@#{ip} "
node.set[:scp_cmd] = "scp -ri #{ssh_key_file} #{ssh_options} SOURCE #{user}@#{ip}:DEST "
node.set[:rsync_cmd] = "rsync -ae \"ssh -i #{ssh_key_file} #{ssh_options}\" SOURCE #{user}@#{ip}:DEST "
