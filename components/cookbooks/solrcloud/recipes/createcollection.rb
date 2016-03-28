#
# Cookbook Name:: solrcloud
# Recipe:: createcollection.rb
#
# The recipie creates collection to the solr cloud.
#
#

ci = node.workorder.ci.ciAttributes;
args = ::JSON.parse(node.workorder.arglist)
collection_name = args["PhysicalCollectionName"]
num_shards = args["NumberOfShards"]
replication_factor = args["ReplicationFactor"]
max_shards_per_node = args["MaxShardsPerNode"]

config_name = ci[:config_name]
custom_config_name = ci[:custom_config_name]
custom_config_name = custom_config_name.delete(' ');

if !"#{num_shards}".empty?
  num_shards = num_shards.delete(' ');
end
if !"#{replication_factor}".empty?
  replication_factor = replication_factor.delete(' ');
end
if !"#{max_shards_per_node}".empty?
  max_shards_per_node = max_shards_per_node.delete(' ');
end
if !"#{collection_name}".empty?
  collection_name = collection_name.delete(' ');
end

begin
  if !"#{custom_config_name}".empty?
    Chef::Log.info('Download custom config through zookeeper ZkCLI')
    bash 'download_custom_config' do
      code <<-EOH
        cd "#{node['solr']['user']}"
        java -classpath .:#{node['user']['dir']}/solr-war-lib/* org.apache.solr.cloud.ZkCLI -cmd downconfig -zkhost #{zkpfqdn} -confdir #{node['user']['dir']}/solr-config/#{custom_config_name} -confname #{custom_config_name}
      EOH
    end
    if !"#{collection_name}".empty? || !"#{num_shards}".empty? || !"#{replication_factor}".empty? || !"#{max_shards_per_node}".empty?
      bash 'create_collection_w_custom_config' do
        user "#{node['solr']['user']}"
        Chef::Log.info("http://#{node['ipaddress']}:8080/solr/admin/collections?action=CREATE&name=#{collection_name}&numShards=#{num_shards}&replicationFactor=#{replication_factor}&maxShardsPerNode=#{max_shards_per_node}&collection.configName=#{custom_config_name}")
        code <<-EOH
          curl 'http://#{node['ipaddress']}:8080/solr/admin/collections?action=CREATE&name=#{collection_name}&numShards=#{num_shards}&replicationFactor=#{replication_factor}&maxShardsPerNode=#{max_shards_per_node}&collection.configName=#{custom_config_name}'
        EOH
      end
    end
  else
    if !"#{collection_name}".empty? || !"#{num_shards}".empty? || !"#{replication_factor}".empty? || !"#{max_shards_per_node}".empty?
      bash 'create_collection_w_default_config' do
        user "#{node['solr']['user']}"        
        Chef::Log.info("http://#{node['ipaddress']}:8080/solr/admin/collections?action=CREATE&name=#{collection_name}&numShards=#{num_shards}&replicationFactor=#{replication_factor}&maxShardsPerNode=#{max_shards_per_node}&collection.configName=#{config_name}")
        code <<-EOH
          curl 'http://#{node['ipaddress']}:8080/solr/admin/collections?action=CREATE&name=#{collection_name}&numShards=#{num_shards}&replicationFactor=#{replication_factor}&maxShardsPerNode=#{max_shards_per_node}&collection.configName=#{config_name}'
        EOH
      end
    end
  end
rescue
  raise "By default it uses custom config to create collection .#{custom_config_name} custom config is not uploaded to zookeeper and failed to create collection."
ensure
  puts "End of Creating collection"
end



