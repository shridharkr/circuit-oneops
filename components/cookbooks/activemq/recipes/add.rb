#
# Cookbook Name:: activemq
# Recipe:: add
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

include_recipe "activemq::externalstorage"

tmp = Chef::Config[:file_cache_path]
version = node['activemq']['version']
activemq_home = "#{node['activemq']['installpath']}/apache-activemq-#{version}"
logpath="#{node['activemq']['logpath']}"

tarball = "/activemq/#{version}/apache-activemq-#{version}-bin.tar.gz"
dest_file = "#{tmp}/apache-activemq-#{version}-bin.tar.gz"

runasuser ="#{node['activemq']['runasuser']}"

# Jetty beans are different for 5.13.0 onwards
config_ver = "#{version == '5.13.0' ? '5.13.0' :''}"

# Try component mirrors first, if empty try cloud mirrors, if empty use cookbook mirror attribute
source_list = JSON.parse(node.activemq.mirrors).map! { |mirror| "#{mirror}/#{tarball}" }
if source_list.empty?
    cloud_name = node[:workorder][:cloud][:ciName]
    mirrors = JSON.parse(node[:workorder][:services][:mirror][cloud_name][:ciAttributes][:mirrors])
    source_list = mirrors['apache'].split(",").map { |mirror| "#{mirror}/#{tarball}" }
end
source_list = [node['activemq']['src_mirror']] if source_list.empty?

users=[]
usersstr=''

JSON.parse(node[:activemq][:users]).keys.each do |k|
    users.push(k)
end

userstr=users.join(",")
Chef::Log.info("Users:  #{userstr}")

# Download ActiveMQ binary
unless File.exists?("#{activemq_home}/bin/activemq")

    shared_download_http source_list.join(',') do
        path dest_file
        action :create
        if node[:activemq][:checksum] && !node[:activemq][:checksum].empty?
            checksum node[:activemq][:checksum]
        end
    end
end

#extract the tar
execute "tar zxf #{dest_file}" do
    cwd "#{node['activemq']['installpath']}"

end

directory "/data" do
    mode 00755
    owner "#{runasuser}"
    group "#{runasuser}"
    recursive true
end

directory "/log" do
    mode 00755
    owner "#{runasuser}"
    group "#{runasuser}"
    recursive true
end

directory "#{logpath}" do
    mode 00755
    owner "#{runasuser}"
    group "#{runasuser}"
    recursive true
end

arch = (node['kernel']['machine'] == 'x86_64') ? 'x86-64' : 'x86-32'

#change permission
file "#{activemq_home}/bin/activemq" do
    owner "#{runasuser}"
    group "#{runasuser}"
    mode '0755'
end

link '/etc/init.d/activemq' do
    to "#{activemq_home}/bin/linux-#{arch}/activemq"
end

# control script via template for adminstatus / cloud priority
template "#{activemq_home}/bin/linux-#{arch}/activemq" do
    source "init_activemq.erb"
    mode 0755
end

# Symlink so the default wrapper.conf can find the native wrapper library
link "#{activemq_home}/bin/linux" do
    to "#{activemq_home}/bin/linux-#{arch}"
end

service 'activemq' do
    supports :restart => true, :status => true, :stop => true, :start => true
    action [:stop]
end

# Create a generic 'activemq' symlink for easy access.
link "/#{node['activemq']['installpath']}/activemq" do
    to "#{activemq_home}"
end

# Symlink the wrapper's pidfile location into /var/run
link '/var/run/activemq.pid' do
    to "#{activemq_home}/bin/linux/ActiveMQ.pid"
    not_if 'test -f /var/run/activemq.pid'
end

template "#{activemq_home}/bin/linux/wrapper.conf" do
    source "wrapper.conf.erb"
    mode 0644
    variables({
        :datadirectory  => node[:activemq][:datapath],
        :logpath =>  node[:activemq][:logpath],
        :logsize => node[:activemq][:logsize]
    })
    notifies :stop, 'service[activemq]'
end

link '/var/run/activemq.pid' do
    to "#{activemq_home}/bin/ActiveMQ.pid"
    not_if 'test -f /var/run/activemq.pid'
end

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
        :authenabled => node[:activemq][:authenabled]
    })
    mode 0644
end

template "#{activemq_home}/conf/activemq.xml" do
    source 'activemq.xml.erb'
    variables({
        :datadirectory => node[:activemq][:datapath],
        :storeusage => node[:activemq][:storeusage],
        :tempusage => node[:activemq][:tempusage],
        :jvmheap => node[:activemq][:jvmheap]
    })
    mode 0644
end
#for backward compatibilty

template "#{activemq_home}/conf/credentials.properties" do
    source 'credentials.properties.erb'
    variables({
        :adminusername => node[:activemq][:adminusername],
        :adminpassword => node[:activemq][:adminpassword]
    })
    mode 0644
end

template "#{activemq_home}/conf/users.properties" do
    source 'users.properties.erb'
    variables({
        :adminusername => node[:activemq][:adminusername],
        :adminpassword => node[:activemq][:adminpassword]
    })
    mode 0644
end

template "#{activemq_home}/conf/groups.properties" do
    source 'groups.properties.erb'
    variables({
        :adminusername => node[:activemq][:adminusername],
        :users => userstr
    })
    mode 0644
end

template "#{activemq_home}/conf/log4j.properties" do
    source 'log4j.properties.erb'
    variables({
        :logpath => node[:activemq][:logpath],
        :logsize => node[:activemq][:logsize]
    })
    mode 0644
end

template "#{activemq_home}/webapps/admin/decorators/header.jsp" do
    source "header.jsp.erb"
    mode 0644
end

template "#{activemq_home}/webapps/admin/message.jsp" do
    source "message.jsp.erb"
    mode 0644
end

template "#{activemq_home}/webapps/admin/browse.jsp" do
    source "browse.jsp.erb"
    mode 0644
end

template "#{activemq_home}/webapps/admin/queues.jsp" do
    source "queues.jsp.erb"
    mode 0644
end

template "#{activemq_home}/webapps/admin/subscribers.jsp" do
   source "subscribers.jsp.erb"
   mode 0644
end

template "#{activemq_home}/webapps/admin/topics.jsp" do
    source "topics.jsp.erb"
    mode 0644
end

template "#{activemq_home}/conf/jmx.access" do
    source "jmx.access.erb"
    mode 0644
end

template "#{activemq_home}/conf/login.config" do
    source "login.config.erb"
    mode 0644
end

template "#{activemq_home}/conf/jmx.password" do
    source "jmx.password.erb"
    mode 0644
end

cookbook_file "#{activemq_home}/amq-messaging-resource.jar" do
    source 'amq-messaging-resource.jar'
    owner "#{runasuser}"
    group "#{runasuser}"
    mode '0777'
    action :create
end

execute "chown-user" do
    command "chown -R #{runasuser}:#{runasuser} /#{node['activemq']['installpath']}/activemq"
    command "chown -R #{runasuser}:#{runasuser} /#{node['activemq']['installpath']}/apache*"
    action :run
end

directory '/etc/sysconfig' do
  owner 'activemq'
  group 'activemq'
end

template '/etc/sysconfig/activemq' do
  source 'sysconfig.erb'
  mode 0755
  owner 'activemq'
  group 'activemq'
end

execute "Move API" do
    cwd "#{activemq_home}/webapps"
    command "rm -rf api "
    only_if {node.activemq.restapisupport == 'false' && File.exists?("#{activemq_home}/webapps/api/WEB-INF/web.xml")}
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

template '/opt/nagios/libexec/check_activemq_process.sh' do
    source 'check_activemq_process.sh.erb'
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
