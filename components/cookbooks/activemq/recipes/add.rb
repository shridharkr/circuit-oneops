#
# Cookbook Name:: activemq
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
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


tmp = Chef::Config[:file_cache_path]
version = node['activemq']['version']
activemq_home = "#{node['activemq']['home']}/apache-activemq-#{version}"


# Find major, minor version
vMj, vMn = version.split(".")
# Config templates are same for 5.9 and later
config_ver = "#{vMj+ '.' + vMn == '5.5' ? '5.5' :''}"
Chef::Log.info("ActiveMq config version : #{config_ver}") if !config_ver.empty?


tarball = "/activemq/#{version}/apache-activemq-#{version}-bin.tar.gz"
dest_file = "#{tmp}/apache-activemq-#{version}-bin.tar.gz"


# Try component mirrors first, if empty try cloud mirrors, if empty use cookbook mirror attribute
source_list = JSON.parse(node.activemq.mirrors).map! { |mirror| "#{mirror}/#{tarball}" }
if source_list.empty?
  cloud_name = node[:workorder][:cloud][:ciName]
  mirrors = JSON.parse(node[:workorder][:services][:mirror][cloud_name][:ciAttributes][:mirrors])
  source_list = mirrors['apache'].split(",").map { |mirror| "#{mirror}/#{tarball}" }
end
source_list = [node['activemq']['src_mirror']] if source_list.empty?


# Download ActiveMQ binary
unless File.exists?("#{activemq_home}/bin/activemq")

  shared_download_http source_list.join(',') do
    path dest_file
    action :create
    if node[:activemq][:checksum] && !node[:activemq][:checksum].empty?
      checksum node[:activemq][:checksum]
    end
  end

  execute "tar zxf #{dest_file}" do
    cwd "/opt"
  end

end

file "#{activemq_home}/bin/activemq" do
  owner 'root'
  group 'root'
  mode '0755'
end

# TODO: make this more robust
arch = (node['kernel']['machine'] == 'x86_64') ? 'x86-64' : 'x86-32'

link '/etc/init.d/activemq' do
  to "#{activemq_home}/bin/linux-#{arch}/activemq"
end


# control script via template for adminstatus / cloud priority
template "#{activemq_home}/bin/linux-#{arch}/activemq" do
  source "init_activemq.erb"
  mode 0755
end


service 'activemq' do
  supports :restart => true, :status => true, :stop => true, :start => true
  action [:stop]
end


# Symlink so the default wrapper.conf can find the native wrapper library
link "#{activemq_home}/bin/linux" do
  to "#{activemq_home}/bin/linux-#{arch}"
end

# Create a generic 'activemq' symlink for easy access.
link '/opt/activemq' do
  to "#{activemq_home}"
end

# Symlink the wrapper's pidfile location into /var/run
link '/var/run/activemq.pid' do
  to "#{activemq_home}/bin/linux/ActiveMQ.pid"
  not_if 'test -f /var/run/activemq.pid'
end

template "#{activemq_home}/bin/linux/wrapper.conf" do
  source "wrapper#{config_ver}.conf.erb"
  mode 0644
  variables(:pidfile => '/var/run/activemq.pid')
  notifies :restart, 'service[activemq]'
end

# Changes for the authenication
template "#{activemq_home}/conf/jetty-realm.properties" do
  source 'jetty-realm.properties.erb'
  variables({
                :adminusername => node[:activemq][:adminusername],
                :adminpassword => node[:activemq][:adminpassword]
            })

  mode 0644
end

template "#{activemq_home}/conf/jetty.xml" do
  source "jetty#{config_ver}.xml.erb"
  variables({
                :adminconsoleport => node[:activemq][:adminconsoleport],
                :authenabled => node[:activemq][:authenabled],
                :adminconsolesecure => node[:activemq][:adminconsolesecure],
                :adminconsolekeystore => node[:activemq][:adminconsolekeystore],
                :adminconsolekeystorepassword => node[:activemq][:adminconsolekeystorepassword],
            })

  mode 0644
end

template "#{activemq_home}/conf/activemq.xml" do
  source 'activemq.xml.erb'
  variables({
                :transportconnectormap => JSON.parse(node[:activemq][:transportconnector])
            })
  mode 0644
  not_if { File.exists?('/tmp/user.activemq.xml.erb') }
end

template "#{activemq_home}/conf/activemq.xml" do
  local true
  source '/tmp/user.activemq.xml.erb'
  mode 0644
  only_if { File.exists?('/tmp/user.activemq.xml.erb') }
end

template "#{activemq_home}/conf/credentials.properties" do
  source 'credentials.properties.erb'
  variables({
                :brokerusername => node[:activemq][:brokerusername],
                :brokerpassword => node[:activemq][:brokerpassword]
            })

  mode 0644
end

# AMQ patch recipe
include_recipe 'activemq::patch'

directory '/etc/sysconfig' do
  owner 'root'
  group 'root'
end

template '/etc/sysconfig/activemq' do
  source 'sysconfig.erb'
  mode 0755
  owner 'root'
  group 'root'
end


fs = nil
deps = node.workorder.payLoad['DependsOn']
deps.each do |dep|
  if dep['ciClassName'] =~ /Filesystem/
    fs = dep
  end
end

if fs != nil
  mount_point = fs['ciAttributes']['mount_point']
  Chef::Log.info("moving to #{mount_point}")
  bash 'move data dir' do
    code <<-EOH
      mv #{activemq_home}/data/* #{mount_point}
      rm -fr #{activemq_home}/data
      ln -s #{mount_point} #{activemq_home}/data
    EOH
  end
end

if node.workorder.cloud.ciAttributes.priority == "1"
  service 'activemq' do
    supports :restart => true, :status => true, :stop => true, :start => true
    action [:enable, :start]
  end
else
  # disable and stop secondary
  service 'activemq' do
    supports :restart => true, :status => true, :stop => true, :start => true
    action [:disable, :stop]
  end  
end

# Monitor scripts
template '/opt/nagios/libexec/check_activemq.rb' do
  source 'check_activemq.rb.erb'
  mode 0755
  owner 'oneops'
  group 'oneops'
end

template '/opt/nagios/libexec/check_activemq_mem.rb' do
  source 'check_activemq_mem.rb.erb'
  mode 0755
  owner 'oneops'
  group 'oneops'
end

