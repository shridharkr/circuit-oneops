#
# Cookbook Name:: solr-monitor
# Attributes:: default.rb
#
#
# @walmartlabs
#

default['user']['dir'] = "/app";
default['solr']['user'] = "app";
default['script']['dir'] = "/app/scripts";
default['solr']['script_version'] = "#{node['script']['dir']}/scripts_version";
default['monitor']['dir'] = "#{node['solr']['script_version']}/solr-monitoring";
default['dashboardscript']['dir'] = "#{node['solr']['script_version']}/solr-monitoring/dashboards";
default['clusterstatus']['uri'] = "solr/admin/collections?action=CLUSTERSTATUS&wt=json";

default[:'solr-monitor'][:src_mirror] = 'http://gec-maven-nexus.walmart.com/nexus/content/repositories/pangaea_releases/com/walmart/fl/monitor/solr'
default[:'solr-monitor'][:mirrors] = '[]'



