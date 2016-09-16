# rubocop:disable LineLength
###############################################################################
# Cookbook Name:: tomcat_8-5
# Recipe:: add_repo
# Purpose:: This recipe is used to do the initial setup of the Tomcat system
#     settings before the Tomcat binaries are installed onto the server.
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
# Setup Tomcat User and Group
#   The tomcat_user and tomcat_group variables will be grabbed from the user
#     response in the metadata.rb file if different from the default values.
###############################################################################
if node['tomcat'].key?('tomcat_user') && !node['tomcat']['tomcat_user'].empty?
  node.set['tomcat_user'] = node['tomcat']['tomcat_user']
end

if node['tomcat'].key?('tomcat_group') && !node['tomcat']['tomcat_group'].empty?
  node.set['tomcat_group'] = node['tomcat']['tomcat_group']
end

group "#{node.tomcat_group}" do
  action :create
end

user "#{node.tomcat_user}" do
  home "/home/#{node.tomcat_user}"
  group "#{node.tomcat_group}"
  system true
  action :create
end

###############################################################################
# Setup server.xml variables
#   1 - Set the protocol type to org.apache.coyote.http11.Http11Protocol
#   2 - Set the advanced_NIO_connector_config to either the user-entered value
#       or the default value
#   3 - Log the advanced_NIO_connector_config value to the Chef log
#   4 - Define the tomcat_version_name
#   5 - Set the max and min threads for Tomcat's threadpool
#   6 - See if a keystore is required
#   7 - If keystore is required, log that it is and get values for keystore
#       settings.
#   8 - Check if both HTTP and HTTPS connectors are disabled
#       If so, warn the customer that the instance may not be reachable
#   9 - If HTTPS is enabled, define the TLS protocols desired.
#       If HTTPS is enabled and the user manually disabled all TLS protocols
#       from the UI, TLSv1.2 is enabled.
###############################################################################
#=1=#
node.set['tomcat']['connector']['protocol'] = 'org.apache.coyote.http11.Http11Protocol'
#=2=#
if node['tomcat'].key?('advanced_NIO_connector_config')
  if !node['tomcat']['advanced_NIO_connector_config'].empty?
    node.set['tomcat']['connector']['advanced_NIO_connector_config'] = node['tomcat']['advanced_NIO_connector_config']
  else
    node.set['tomcat']['connector']['advanced_NIO_connector_config'] = '{"connectionTimeout":"20000","maxKeepAliveRequests":"100"}'
  end
else
  node.set['tomcat']['connector']['advanced_NIO_connector_config'] = '{"connectionTimeout":"20000","maxKeepAliveRequests":"100"}'
end
#=3=#
Chef::Log.info(" protocol  #{node['tomcat']['connector']['protocol']} - connector config #{node['tomcat']['connector']['advanced_connector_config']} ssl_configured : #{node['tomcat']['connector']['ssl_configured']}")
#=4=#
tomcat_version_name = node.workorder.rfcCi.ciAttributes.version
#tomcat_version_name = node.workorder.rfcCi.ciBaseAttributes.version
#tomcat_version_name = get_attribute_value('version')
node.set['tomcat']['tomcat_version_name'] = tomcat_version_name
#Chef::Log.warn("tomcat_version_name = #{tomcat_version_name} ")
Chef::Log.warn("tomcat_version_name = #{node['tomcat']['tomcat_version_name']} ")
#Chef::Log.warn("tomcat_version_name is also #{get_attribute_value('version')}")
#=5=#
node.set['tomcat']['max_threads'] = node['tomcat']['max_threads']
node.set['tomcat']['min_spare_threads'] = node['tomcat']['min_spare_threads']
#=6=#
depends_on_keystore = node.workorder.payLoad.DependsOn.reject { |d| d['ciClassName'] !~ /Keystore/ }
#=7=#
if !depends_on_keystore.nil? && !depends_on_keystore.empty?
  Chef::Log.info("This does depend on keystore with filename: #{depends_on_keystore[0]['ciAttributes']['keystore_filename']} ")
  node.set['tomcat']['keystore_path'] = depends_on_keystore[0]['ciAttributes']['keystore_filename']
  node.set['tomcat']['keystore_pass'] = depends_on_keystore[0]['ciAttributes']['keystore_password']
  Chef::Log.info("Stashed keystore_path = #{node['tomcat']['keystore_path']}")
end
#=8=#
if node['tomcat']['https_NIO_connector_enabled'].nil? || node['tomcat']['https_NIO_connector_enabled'] == 'false'
  if node['tomcat']['http_NIO_connector_enabled'].nil? || node['tomcat']['http_NIO_connector_enabled'] == 'false'
    Chef::Log.warn('HTTP AND HTTPS ARE DISABLED. This may result in NO COMMUNICATION to the Tomcat instance.')
  end
end
#=9=#
if !node['tomcat']['https_NIO_connector_enabled'].nil? || node['tomcat']['https_NIO_connector_enabled'] == 'true'
  node.set['tomcat']['connector']['ssl_configured_protocols'] = ''
  if node['tomcat']['tlsv11_protocol_enabled'] == 'true'
    node['tomcat']['connector']['ssl_configured_protocols'].concat('TLSv1.1,')
  end
  if node['tomcat']['tlsv12_protocol_enabled'] == 'true'
    node['tomcat']['connector']['ssl_configured_protocols'].concat('TLSv1.2,')
  end
  node['tomcat']['connector']['ssl_configured_protocols'].chomp!(',')
  if node['tomcat']['connector']['ssl_configured_protocols'] == ''
    Chef::Log.warn('HTTPS is enabled, but all TLS protocols were disabled. Defaulting to TLSv1.2 only.')
    node.set['tomcat']['connector']['ssl_configured_protocols'] = 'TLSv1.2'
  end
end

###############################################################################
# Auto Startup Script
#   The script in init.d allows the Tomcat instance to automcatically startup
#   when the server is restarted.
###############################################################################
service 'tomcat' do
  only_if { File.exist?('/etc/init.d/' + tomcat_version_name) }
  service_name tomcat_version_name
  supports restart: true, reload: true, status: true
end

depends_on = node.workorder.payLoad.DependsOn.reject{ |d| d['ciClassName'] !~ /Javaservicewrapper/ }
if (!depends_on.nil? && !depends_on.empty? && File.exist?('/etc/init.d/' + tomcat_version_name))
  # Delete the tomcat init.d daemon
  file '/etc/init.d/' + tomcat_version_name do
    action :delete
  end
end

###############################################################################
# Run Install Cookbook for Tomcat Binaries
###############################################################################
include_recipe 'tomcat-85::add_repo'
###############################################################################
# Setup Log Rotation
#   The logrotate.d script and these cron jobs will clean out Tomcat logs
#   older than seven days old.
###############################################################################
template '/etc/logrotate.d/tomcat' do
  source 'logrotate.erb'
  owner 'root'
  group 'root'
  mode '0755'
end

cron 'logrotatecleanup' do
  minute '0'
  command "ls -t1 #{node.tomcat.logfiles_path}/access_log*|tail -n +7|xargs rm -r"
  mailto '/dev/null'
  action :create
end

cron 'logrotate' do
  minute '0'
  command 'sudo /usr/sbin/logrotate /etc/logrotate.d/tomcat'
  mailto '/dev/null'
  action :create
end

###############################################################################
# Setup for webapps Directory
###############################################################################
%w(webapp_install_dir logfiles_path work_dir context_dir).each do |dir|
  dir_name = node['tomcat'][dir]
  directory dir_name do
    action :create
    recursive true
    not_if "test -d #{dir_name}"
  end
  execute "chown -R #{node.tomcat_user}:#{node.tomcat_group} #{dir_name}"
end

###############################################################################
#   Create Config Files From Templates
#   1 - server.xml
#   2 - tomcat-users.xml
#   3 - manager.xml
#   4 - policy.d directory
#   5 - 50local.policy
#   6 - init.d script
###############################################################################
#=1=#
template "#{node['tomcat']['instance_dir']}/conf/server.xml" do
  source 'server.xml.erb'
  owner 'root'
  group 'root'
  mode '0644'
end
#=2=#
template "#{node['tomcat']['instance_dir']}/conf/tomcat-users.xml" do
  source 'tomcat-users.xml.erb'
  owner 'root'
  group 'root'
  mode '0644'
end
#=3=#
#template '/etc/#{tomcat_version_name}/Catalina/localhost/manager.xml' do
#  source 'manager.xml.erb'
#  owner 'root'
#  group 'root'
#  mode '0644'
#end
#=4=#
directory "#{node['tomcat']['instance_dir']}/conf/policy.d" do
  action :create
  owner 'root'
  group 'root'
end
#=5=#
template "#{node['tomcat']['instance_dir']}/conf/policy.d/50local.policy" do
  source '50local.policy.erb'
  owner 'root'
  group 'root'
  mode '0644'
end
#=6=#
template '/etc/init.d/tomcat' do
  source 'tomcat#{major_version}_initd.erb'
  owner 'root'
  group 'root'
  mode '0755'
end

###############################################################################
# Nagios Stuff
###############################################################################

template '/opt/nagios/libexec/check_tomcat.rb' do
  source 'check_tomcat.rb.erb'
  owner 'oneops'
  group 'oneops'
  mode '0755'
end

template '/opt/nagios/libexec/check_ecv.rb' do
  source 'check_ecv.rb.erb'
  owner 'oneops'
  group 'oneops'
  mode '0755'
end

=begin
include_recipe 'tomcat-85::versionstatus'
template '/opt/nagios/libexec/check_tomcat_app_version.sh' do
  source 'check_tomcat_app_version.sh.erb'
  variables(
    versioncheckscript: node['versioncheckscript']
  )
  owner 'oneops'
  group 'oneops'
  mode '0755'
end
=end

###############################################################################
# Do Restarts of Tomcat for All Changes Except Deletions
###############################################################################

if !depends_on.nil? && !depends_on.empty? && depends_on[0][:rfcAction] != 'delete'
  include_recipe 'javaservicewrapper::restart'
else
  service 'tomcat' do
    service_name tomcat_version_name
    action [:enable]
  end
  #include_recipe 'tomcat-85::restart'
end

###############################################################################
# Additional Recipes
#   These recipes will be called after the rest of the add.rb file is run.
###############################################################################
include_recipe 'tomcat-85::default'
#include_recipe 'tomcat-85::start'
#include_recipe 'tomcat-85::stop'
