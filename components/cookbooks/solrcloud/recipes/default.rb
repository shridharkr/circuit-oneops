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
solr_version = ci['solr_version']
solr_format = ci['solr_format']
solr_package_type = ci['solr_package_type']
solr_file_name = "#{solr_package_type}-"+"#{solr_version}."+"#{solr_format}";

# Automatically download the package from external location
solr_url = "#{solr_base_url}#{solr_package_type}/#{solr_version}/#{solr_file_name}";

solr_filepath = "#{node['user']['dir']}/#{solr_file_name}";


Chef::Log.info("Download solr from gec-nexus: #{solr_url}")
remote_file solr_filepath do
  source "#{solr_url}"
  owner "#{node['solr']['user']}"
  group "#{node['solr']['user']}"
  mode '0644'
  action :create_if_missing
end



