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
# Cookbook Name:: dotnetcli
# Recipe:: add
#

#include_recipe "java::#{node[:java][:flavor]}"

Chef::Log.info("Executing Dotnet CLI add script")

#binarydistname = node[:dotnetcli][:mirror_loc].split('/').last 	#Centos-0.0.5.tar.gz
filePath = node.workorder.rfcCi.ciAttributes[:folderpath]
operatingsystem = node.workorder.rfcCi.ciAttributes[:ostype]
url_public = node.workorder.rfcCi.ciAttributes[:src_url]
destfile = "#{filePath}/Centos-0.0.5.tar.gz"

Chef::Log.info("DotNet Installation directory [ #{filePath} ]")
Chef::Log.info("DotNet destination file [ #{destfile} ]")
Chef::Log.info("DotNet destination file [ #{operatingsystem} ]")
Chef::Log.info("DotNet destination file [ #{url_public} ]")

# Getting mirror location for dotnet package
cloud = node.workorder.cloud.ciName
cookbook = node.app_name.downcase
Chef::Log.info("Getting mirror service for #{cookbook}, cloud: #{cloud}")

mirror_svc = node[:workorder][:services][:mirror]
mirror = JSON.parse(mirror_svc[cloud][:ciAttributes][:mirrors]) if !mirror_svc.nil?

base_url = ''
# Search for dotnetcli mirror
base_url = mirror[:dotnetcli] if !mirror.nil? && mirror.has_key?(:dotnetcli)

if base_url.empty?
  # Search for cookbook default nexus mirror.
  Chef::Log.info('dotnetcli mirror is empty. ')
#  base_url = node[cookbook][:nexus_mirror] if base_url.empty?
  # Nexus url format
#  base_url = "#{base_url}/#{pkg}/#{artifact}"
end

#Create directory for downloading package


execute "createdirectory" do
  command "mkdir -p #{filePath}"
end

remote_file "#{destfile}" do
  source "http://repo.wal-mart.com/content/repositories/walmart/Microsoft/Dotnet/CLI/Centos/0.0.5/Centos-0.0.5.tar.gz"
end
Chef::Log.info("Downloaded DotNet binary file to destination")


timewait = 15
Chef::Log.info("waiting #{timewait} seconds to create vm...")
sleep timewait

Chef::Log.info("Installing..")

execute "extract_tar" do
  command "tar -zxf #{destfile}"
  cwd "#{filePath}"
end
