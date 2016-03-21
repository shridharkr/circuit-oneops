#
# Cookbook Name:: solrcloud
# Attributes:: default.rb
#
# This recipe declares all the variables.
#
#

default['user']['dir'] = "/app";
default['solr']['user'] = "app";

node.set['tomcat_version'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }.first[:ciAttributes]['version']
node.set['protocol'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }.first[:ciAttributes]['protocol']
node.set['executor_name'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }.first[:ciAttributes]['executor_name']
node.set['enable_method_trace'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }.first[:ciAttributes]['enable_method_trace']
node.set['server_header_attribute'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }.first[:ciAttributes]['server_header_attribute']
node.set['ssl_port'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }.first[:ciAttributes]['ssl_port']
node.set['advanced_connector_config'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }.first[:ciAttributes]['advanced_connector_config']

default['executor_name'] = "#{node['executor_name']}";
default['enable_method_trace'] = "#{node['enable_method_trace']}";
default['server_header_attribute'] = "#{node['server_header_attribute']}";
default['ssl_port'] = "#{node['ssl_port']}";
default['advanced_connector_config'] = "#{node['advanced_connector_config']}";
default['protocol'] = "#{node['protocol']}";

default['tomcatversion'] = "#{node['tomcat_version']}"[0,1];
default['tomcat']['dir'] = "#{node['user']['dir']}/tomcat#{node['tomcatversion']}";

default['clusterstatus']['uri'] = "solr/admin/collections?action=CLUSTERSTATUS&wt=json";




