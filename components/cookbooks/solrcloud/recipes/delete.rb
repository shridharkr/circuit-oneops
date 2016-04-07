#
# Cookbook Name:: solrcloud
# Recipe:: delete.rb
#
# This recipe deletes the directories.
#
#

Chef::Log.info('Deleting cores directory')
directory "#{node['user']['dir']}/solr-cores" do
  only_if { ::File.directory?("#{node['user']['dir']}/solr-cores") }
  recursive true
  action :delete
end

Chef::Log.info("Deleting tomcat#{node['tomcatversion']} directory")
directory "#{node['user']['dir']}/tomcat#{node['tomcatversion']}" do
  only_if { ::File.directory?("#{node['user']['dir']}/tomcat#{node['tomcatversion']}") }
  recursive true
  action :delete
end

Chef::Log.info('Deleting solr-war-lib directory')
directory "#{node['user']['dir']}/solr-war-lib" do
  only_if { ::File.directory?("#{node['user']['dir']}/solr-war-lib") }
  recursive true
  action :delete
end

Chef::Log.info("Deleting #{node['user']['dir']}/tmp/tgz directory")
directory "#{node['user']['dir']}/tmp/tgz" do
  only_if { ::File.directory?("#{node['user']['dir']}/tmp/tgz") }
  recursive true
  action :delete
end

