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
# Recipe:: replace
#
# builds a list of entries based on entrypoint, aliases, and  then sets then in the set_dns_entries recipe
# no ManagedVia - recipes will run on the gw


cloud_name = node[:workorder][:cloud][:ciName]
provider = node[:workorder][:services][:dns][cloud_name][:ciClassName].gsub("cloud.service.","").downcase

if provider =~ /azuredns/
  include_recipe 'azuredns::remove_old_aliases'
else
  include_recipe "fqdn::remove_old_aliases_"+provider
end

include_recipe "fqdn::add"
