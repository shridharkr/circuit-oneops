#
# Cookbook Name:: solrcloud
# Recipe:: addreplica.rb
#
# The recipie adds replica to the solr cloud.
#
#

args = ::JSON.parse(node.workorder.arglist)
collection_name = args["PhysicalCollectionName"]
time = Time.now.getutc.to_i

begin
  bash 'add_replica' do
    user "#{node['solr']['user']}"
	  code <<-EOH
	    curl '#{node['solr']['core_url']}action=CREATE&collection=#{collection_name}&name=#{node['ipaddress']}_#{collection_name}_#{time}'
	  EOH
    not_if { "#{collection_name}".empty? }
  end
rescue
  Chef::Log.error("Failed to add replica. Collection '#{collection_name}' may not exists.")
ensure
  puts "End of add_replica execution."
end


