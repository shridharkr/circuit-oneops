#
# Cookbook Name:: solrcloud
# Recipe:: default.rb
#
# The recipie downloads the solr.tgz and log4j jars from nexus.
#
#

extend Java::Util

# Wire java util to chef resources.
Chef::Resource::RubyBlock.send(:include, Java::Util)

ci = node.workorder.rfcCi.ciAttributes;

solr_base_url = ci['solr_url']
solr_version = @solr_version = ci['solr_version']
solr_format = @solr_format = ci['solr_format']
solr_package_type = @solr_package_type = ci['solr_package_type']
solr_file_name = "#{solr_package_type}-"+"#{solr_version}."+"#{solr_format}";

# Automatically download the package from external location
solr_url = "#{solr_base_url}#{solr_package_type}/#{solr_version}/#{solr_file_name}";

solr_filepath = "#{node['user']['dir']}/#{solr_file_name}";

log4j_path = "#{node['user']['dir']}/#{node['log4j']['name']}"
jcl_over_slf4j_path = "#{node['user']['dir']}/#{node['jcl_over_slf4j']['name']}"
jul_to_slf4j_path = "#{node['user']['dir']}/#{node['jul_to_slf4j']['name']}"
slf4j_api_path = "#{node['user']['dir']}/#{node['slf4j_api']['name']}"
slf4j_log4j12_path = "#{node['user']['dir']}/#{node['slf4j_log4j12']['name']}"


Chef::Log.info("Download solr from gec-nexus: #{solr_url}")
remote_file solr_filepath do
  source "#{solr_url}"
  owner "#{node['solr']['user']}"
  group "#{node['solr']['user']}"
  mode '0644'
  action :create_if_missing
end

Chef::Log.info('Download log4j.jar from gec-nexus')
remote_file log4j_path do
  source node['log4j']['url']
  owner "#{node['solr']['user']}"
  group "#{node['solr']['user']}"
  mode '0644'
  action :create_if_missing
end

Chef::Log.info('Download jcl-over-slf4j.jar from gec-nexus')
remote_file jcl_over_slf4j_path do
  source node['jcl_over_slf4j']['url']
  owner "#{node['solr']['user']}"
  group "#{node['solr']['user']}"
  mode '0644'
  action :create_if_missing
end

Chef::Log.info('Download jcl-to-slf4j.jar from gec-nexus')
remote_file jul_to_slf4j_path do
  source node['jul_to_slf4j']['url']
  owner "#{node['solr']['user']}"
  group "#{node['solr']['user']}"
  mode '0644'
  action :create_if_missing
end

Chef::Log.info('Download slf4j-api.jar from gec-nexus')
remote_file slf4j_api_path do
  source node['slf4j_api']['url']
  owner "#{node['solr']['user']}"
  group "#{node['solr']['user']}"
  mode '0644'
  action :create_if_missing
end

Chef::Log.info('Download slf4j-log4j12.jar from gec-nexus')
remote_file slf4j_log4j12_path do
  source node['slf4j_log4j12']['url']
  owner "#{node['solr']['user']}"
  group "#{node['solr']['user']}"
  mode '0644'
  action :create_if_missing
end
