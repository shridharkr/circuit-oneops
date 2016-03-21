#
# Cookbook Name:: solr-monitor
# Recipe:: remove.rb
#
# This recipe removes the directories.
# @walmartlabs
#

ci = node.workorder.rfcCi.ciAttributes;
solrmonitoringscripts_url = ci[:solrmonitorscripts_url]
solr_monitor_version = solrmonitoringscripts_url.split("/")[solrmonitoringscripts_url.split.length - 3];

Chef::Log.info "Deleting files from /app"
bash 'unlink_script_version' do
  code <<-EOH
    unlink "#{node['solr']['script_version']}"
  EOH
end

Chef::Log.info "Deleting files from /app"
bash 'deletefiles' do
  code <<-EOH
	cd "#{node['user']['dir']}"
	rm -fr #{node['script']['dir']}/*
  EOH
end

