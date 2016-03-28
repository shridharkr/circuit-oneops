#
# Cookbook Name:: solrcloud
# Recipe:: replacereplica.rb
#
# This recipe deletes the dead replicas adds the new node as replica to the solrcloud.
#
#

require 'open-uri'
require 'json'
require 'uri'

ci = node.workorder.rfcCi.ciAttributes;
collection_name = ci['collection_name']
time = Time.now.getutc.to_i

zk_select = ci['zk_select']
if "#{zk_select}".include? "External"
  ruby_block 'add_replaced_replica' do
    block do
      begin
        if !"#{collection_name}".empty?
          request_url = "http://#{node['ipaddress']}:8080/#{node['clusterstatus']['uri']}"
          response = open(request_url).read
          jsonresponse = JSON.parse(response)

          if !jsonresponse["cluster"]["collections"].empty? && !jsonresponse["cluster"]["collections"]["#{collection_name}"].empty?
            shardList = jsonresponse["cluster"]["collections"]["#{collection_name}"]["shards"].keys
            replicaip = '';
            maxShardsPerNode = jsonresponse["cluster"]["collections"]["#{collection_name}"]["maxShardsPerNode"]
            replicationFactor = jsonresponse["cluster"]["collections"]["#{collection_name}"]["replicationFactor"]
            numReplacedReplicas = 0;
            shardList.each do |shard|
              if numReplacedReplicas < maxShardsPerNode
                shardstate = jsonresponse["cluster"]["collections"]["#{collection_name}"]["shards"][shard]["state"]
                if(shardstate == "active")
                  replicaList = jsonresponse["cluster"]["collections"]["#{collection_name}"]["shards"][shard]["replicas"].keys
                  count = 0;
                  replicaip = 0;
                  replicaList.each do |replica|
                    replicastate = jsonresponse["cluster"]["collections"]["#{collection_name}"]["shards"][shard]["replicas"][replica]["state"]
                    if(replicastate != "down")
                      count = count + 1;
                    end
                  end
                  if count < replicationFactor
                    addreplica_url = "#{node['solr']['collection_url']}action=ADDREPLICA&collection=#{collection_name}&shard=#{shard}&node=#{node['ipaddress']}:8080_solr"
                    addreplica_response = open(addreplica_url).read
                    numReplacedReplicas = numReplacedReplicas + 1;
                  else
                    Chef::Log.info("count value for shard #{shard} = #{count}")
                  end
                else ## shard down else block
                  Chef::Log.error("#{shard} state is not in active.")
                end
              end
            end ## shardlist loop end
          else ## collection end else block
            Chef::Log.error("Collections are not created. Replaced node is part of the solrcloud and cannot add as a replica.")
          end  
        else ## collection not passed end block
          Chef::Log.error("Collection name has not passed. Cannot add the replaced node as a replica.")
        end
      rescue
        Chef::Log.error("Exception while requesting clusterstate.")
      end
    end
  end
end


