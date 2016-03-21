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

default['log4j']['version'] = "1.2.17";
default['log4j']['name'] = "log4j-#{node['log4j']['version']}.jar";
default['log4j']['url'] = "http://gec-maven-nexus.walmart.com/nexus/content/groups/public/log4j/log4j/#{node['log4j']['version']}/#{node['log4j']['name']}";

default['jcl_over_slf4j']['version'] = "1.6.6";
default['jcl_over_slf4j']['name'] = "jcl-over-slf4j-#{node['jcl_over_slf4j']['version']}.jar";
default['jcl_over_slf4j']['url'] = "http://gec-maven-nexus.walmart.com/nexus/content/groups/public/org/slf4j/jcl-over-slf4j/#{node['jcl_over_slf4j']['version']}/#{node['jcl_over_slf4j']['name']}";

default['jul_to_slf4j']['version'] = "1.6.6";
default['jul_to_slf4j']['name'] = "jul-to-slf4j-#{node['jul_to_slf4j']['version']}.jar";
default['jul_to_slf4j']['url'] = "http://gec-maven-nexus.walmart.com/nexus/content/groups/public/org/slf4j/jul-to-slf4j/#{node['jul_to_slf4j']['version']}/#{node['jul_to_slf4j']['name']}";

default['slf4j_api']['version'] = "1.6.6";
default['slf4j_api']['name'] = "slf4j-api-#{node['slf4j_api']['version']}.jar";
default['slf4j_api']['url'] = "http://gec-maven-nexus.walmart.com/nexus/content/groups/public/org/slf4j/slf4j-api/#{node['slf4j_api']['version']}/#{node['slf4j_api']['name']}";

default['slf4j_log4j12']['version'] = "1.6.6";
default['slf4j_log4j12']['name'] = "slf4j-log4j12-#{node['slf4j_log4j12']['version']}.jar";
default['slf4j_log4j12']['url'] = "http://gec-maven-nexus.walmart.com/nexus/content/groups/public/org/slf4j/slf4j-log4j12/#{node['slf4j_log4j12']['version']}/#{node['slf4j_log4j12']['name']}";




