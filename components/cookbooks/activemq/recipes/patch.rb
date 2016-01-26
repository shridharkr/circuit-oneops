# This recipe is just to fix the AMQ message display issue.
# https://issues.apache.org/jira/browse/AMQ-5356 . The bug
# is still open as of ActiveMQ version 5.11.1. Apply this
# patch for all AMQ versions greater than 5.9.0.

require 'rubygems'

version = node['activemq']['version']
activemq_home = "#{node['activemq']['home']}/apache-activemq-#{version}"

patch_required = Gem::Version.new(version) > Gem::Version.new('5.9.0')
Chef::Log.info('Applying Activemq patch') if patch_required

cookbook_file "#{activemq_home}/webapps/admin/message.jsp" do
  source 'message.jsp'
  owner 'root'
  group 'root'
  mode '0755'
  only_if { patch_required }
end

cookbook_file "#{activemq_home}/webapps/admin/WEB-INF/tags/form/forEachMapEntry.tag" do
  source 'forEachMapEntry.tag'
  owner 'root'
  group 'root'
  mode '0755'
  only_if { patch_required }
end

