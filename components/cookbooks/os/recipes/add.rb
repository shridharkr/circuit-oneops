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

# Cookbook Name:: os
# Recipe:: add
#

cloud_name = node[:workorder][:cloud][:ciName]
provider = node[:workorder][:services][:compute][cloud_name][:ciClassName].gsub("cloud.service.","").downcase

Chef::Log.info("provider: #{provider} ..")

# common plugins dir that components put their check scripts
execute "mkdir -p /opt/nagios/libexec"

include_recipe "os::packages"
include_recipe "os::network"
include_recipe "os::proxy"
include_recipe "os::time"
include_recipe "os::kernel" unless provider == "docker"
include_recipe "os::security" unless provider == "docker"
include_recipe "os::perf_forwarder"

template "/etc/logrotate.d/oneops" do
  source "logrotate.erb"
  owner "root"
  group "root"
  mode 0644
end

ruby_block 'setup share' do
  only_if { provider == "virtualbox" }
  block do

    rfcCi = node[:workorder][:rfcCi]
    nsPathParts = rfcCi[:nsPath].split("/")
    server_name = rfcCi[:ciName]+'-'+nsPathParts[3]+'-'+nsPathParts[2]+'-'+nsPathParts[1]+'-'+ rfcCi[:ciId].to_s

    cmd = "grep #{server_name} /etc/fstab"
    Chef::Log.info("cmd: #{cmd}")
    result = `#{cmd}`

    if result.to_i != 0 || result.to_s.empty?
      cmd = "echo \"#{server_name} /mnt vboxsf rw 0 0\" >> /etc/fstab"
      Chef::Log.info("cmd: #{cmd}")
      `#{cmd}`
      `mount -a`
    end

  end
end

# install LDAP
attrs = node[:workorder][:rfcCi][:ciAttributes]
services = node[:workorder][:services]

if !services.nil? &&  services.has_key?(:ldap)
  Chef::Log.info("Enable ldap service")
  include_recipe "os::add_ldap"
else
  Chef::Log.info("Disabling ldap service")
  include_recipe "os::delete_ldap"
end

# sshd
execute "cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup"

template "/etc/ssh/sshd_config" do
  source "sshd_config.erb"
  owner "root"
  group "root"
  mode 0644
  only_if { node.platform == "redhat" || node.platform == "centos" }
end

ruby_block 'ssh config' do
  block do

    if node.platform == "redhat" || node.platform == "centos"
      result = `service sshd restart`.to_i

      if result != 0
        Chef::Log.error("new ssh config is bad. fix the sshd_config attribute. reverting and exiting.")
        `cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config ; service sshd restart`
        exit 1
      end

    end

  end
end

Chef::Log.info("Updating security and bash.")

package "bash" do
  action :upgrade
end

case node.platform
when "redhat","centos","fedora"
  if node.platform_version.to_i < 7
    package "yum-security"
    execute "yum -y update --security"
  end
end


include_recipe "os::add-conf-files"

uname_output=`uname -srvmpo`.to_s.gsub("\n","")
puts "***RESULT:osname=#{node.platform}-#{node.platform_version} #{uname_output}"

include_recipe "os::postfix" unless provider == "docker"


if provider =~ /azure/
  Chef::Log.info("Setting DNS label on public_ip")
# creating DNS label for FQDN
  compute_service = node['workorder']['services']['compute'][cloud_name]['ciAttributes']
  express_route_enabled = compute_service['express_route_enabled']
  if express_route_enabled == 'false'
    puts "***RESULT:hostname=#{node.full_hostname}"
  end
end
