# rubocop:disable LineLength
###############################################################################
# Cookbook Name:: tomcat_8-5
# Recipe:: add_repo
# Purpose:: This recipe is used to install the Tomcat binaries onto the server.
#
# Copyright 2010, Opscode, Inc.
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
###############################################################################

###############################################################################
# Setup Base Directory
#   '%w' creates an array with "run, source, software, and build"
#   In the '#{node.tomcat.base}/#{dir}' directory, each of these objects is
#     created recursively.
###############################################################################
%w(run source software build).each do |dir|
  Chef::Log.warn("creating #{node.tomcat.base}/#{dir}")
  directory "#{node.tomcat.base}/#{dir}" do
    mode 0775
    action :create
    recursive true
  end
end

###############################################################################
# Tomcat Download
#   This installed the Tomcat binaries from the repo specified in the cloud's
#   Mirror.
#   1 - Create listof package names based on OS
#   2 - Clean up metadata if OS = rhel
#   3 - If OS is not fedora|redhat|centos, OneOps will check for a lock file.
#     OneOps will retry until lock is gone of it hits 20 retries.
#     Package will install on fedora|redhat|centos and on other OSs once lock
#       is gone.
###############################################################################
=begin
if platform_family?('rhel')
  execute 'yum clean metadata' do
    user 'root'
    group 'root'
  end
end

package "tomcat-8" do
  version "v#{node['tomcat']['tomcat_version_name']}"
end
=end

# create context root of repo path
tarball = "tomcat/tomcat-8/v#{node['tomcat']['tomcat_version_name']}/bin/apache-tomcat-#{node['tomcat']['tomcat_version_name']}.tar.gz"
Chef::Log.warn("context root of repo path is: #{tarball}")

# create parent dir (keep ownership as root) if doesnt exist
Chef::Log.warn("making #{node['tomcat']['config_dir']} directory")
directory node['tomcat']['config_dir'] do
  action :create
  not_if "test -d #{node['tomcat']['config_dir']}"
end
dest_file = "#{node['tomcat']['config_dir']}/apache-tomcat-#{node['tomcat']['tomcat_version_name']}.tar.gz"

#source_list = JSON.parse(node.tomcat.mirrors).map! { |mirror| "#{mirror}/#{tarball}" }

##Get apache mirror configured for the cloud, if no mirror is defined for component.
#if source_list.empty?
  cloud_name = node[:workorder][:cloud][:ciName]
  services = node[:workorder][:cloud][:services]
  Chef::Log.error("Cloud name: #{cloud_name}")
  Chef::Log.error("Services in #{cloud_name}: #{services}")

=begin
  services.each do |service|
    Chef::Log.warn("#{service}")
  end

  if services.nil?
    Chef::Log.error("there are no services")
  end
  if !services.has_key?(:mirror)
    Chef::Log.error("no mirror key")
  end
  if services.nil? || !services.has_key?(:mirror)
    Chef::Log.error("Msg 1: Please make sure  cloud '#{cloud_name}' has mirror service with 'apache' eg {apache=>http://archive.apache.org/dist}")
    exit 1
  end
  mirrors = JSON.parse(services[:mirror][cloud_name][:ciAttributes][:mirrors])
  if mirrors.nil? || !mirrors.has_key?('apache')
    Chef::Log.error("Msg 2: Please make sure  cloud '#{cloud_name}' has mirror service with 'apache' eg {apache=>http://archive.apache.org/dist}")
    exit 1
  end
  mirrors = JSON.parse(node[:workorder][:services][:mirror][cloud_name][:ciAttributes][:mirrors])
  source_list = mirrors['apache'].split(",").map { |mirror| "#{mirror}/#{tarball}" }
#end
=end
#Ignore foodcritic(FC002) warning here.  We need the string interpolation magic to get the correct build version
source_url="http://repos.walmart.com/mirrored-assets/apache.mirrors.pair.com"
source_list="#{source_url}/#{tarball}"
shared_download_http source_list do
  path dest_file
  action :create
  #checksum build_version_checksum["#{build_version}"]   # ~FC002
end
=begin
Chef::Log.error("Download complete. Beginning un-TAR.")

tar_flags = "--exclude webapps/ROOT"
execute "tar #{tar_flags} -zxf #{dest_file}" do
  cwd node['tomcat']['config_dir']
end
=end
=begin
execute "rm -fr tomcat#{major_version}" do
  cwd node['tomcat']['config_dir']
end


link "#{node.tomcat.tomcat_install_dir}/tomcat#{major_version}" do
  to "#{node.tomcat.tomcat_install_dir}/apache-tomcat-#{full_version}"
end
=end
###############################################################################
# End of add_repo.rb
###############################################################################
