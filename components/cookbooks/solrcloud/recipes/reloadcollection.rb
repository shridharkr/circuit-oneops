#
# Cookbook Name:: solrcloud
# Recipe:: reloadcollection.rb
#
# The recipie reloads collection to the solr cloud.
#
#

args = ::JSON.parse(node.workorder.arglist)
collection_name = args["PhysicalCollectionName"]

begin
  bash 'reload_collection' do
    user "#{node['solr']['user']}"
    code <<-EOH
      curl '#{node['solr']['collection_url']}?action=RELOAD&name=#{collection_name}'
    EOH
    not_if { "#{collection_name}".empty? }
  end
rescue
	Chef::Log.error("Failed to reload Collection '#{collection_name}'.")
ensure
	puts "End of reload_collection method. "
end


