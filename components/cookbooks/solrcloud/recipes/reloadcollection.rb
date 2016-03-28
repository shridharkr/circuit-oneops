#
# Cookbook Name:: solrcloud
# Recipe:: reloadcollection.rb
#
# The recipie reloads collection to the solr cloud.
#
#

args = ::JSON.parse(node.workorder.arglist)
collection_name = args["PhysicalCollectionName"]

Chef::Log.info('Reload Collection to Solr Cloud ')
begin
  bash 'reload_collection' do
    user "#{node['solr']['user']}"
    Chef::Log.info("http://#{node['ipaddress']}:8080/solr/admin/collections?action=RELOAD&name=#{collection_name}")
    code <<-EOH
      curl 'http://#{node['ipaddress']}:8080/solr/admin/collections?action=RELOAD&name=#{collection_name}'
    EOH
    not_if { "#{collection_name}".empty? }
  end
rescue
	Chef::Log.error("Failed to reload Collection '#{collection_name}'.")
ensure
	puts "End of reload_collection method. "
end


