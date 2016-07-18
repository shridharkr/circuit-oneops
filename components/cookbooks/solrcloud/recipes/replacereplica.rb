#
# Cookbook Name :: solrcloud
# Recipe :: replacereplica.rb
#
# The recipe adds the new node as replica to the solrcloud.
#

require 'open-uri'
require 'json'
require 'uri'


time = Time.now.getutc.to_i

replacedipAddress = ''
if (!node['zk_select'].include? "Embedded") && (node['solr_version'].start_with? "4.") && (node['solrcloud']['replace_nodes'] == 'true')

  ruby_block 'add_replaced_replica' do
    block do
      begin
        request_url = "http://#{node['ipaddress']}:8080/#{node['clusterstatus']['uri']}"
        Chef::Log.info("request_url -- "+request_url)
        response = open(request_url).read
        jsonresponse = JSON.parse(response)

        if !jsonresponse["cluster"]["collections"].empty?
          collectionList = jsonresponse["cluster"]["collections"].keys
          collectionList.each do |collection|
            shardList = jsonresponse["cluster"]["collections"][collection]["shards"].keys
            maxShardsPerNode = jsonresponse["cluster"]["collections"][collection]["maxShardsPerNode"]
            replicationFactor = jsonresponse["cluster"]["collections"][collection]["replicationFactor"]
            shardList.each do |shard|
              activereplicalist = Array.new()
              downreplicalist = Array.new()
              replicaList = jsonresponse["cluster"]["collections"][collection]["shards"][shard]["replicas"].keys
              replicaList.each do |replica|
                replicastate = jsonresponse["cluster"]["collections"][collection]["shards"][shard]["replicas"][replica]["state"]
                replicaip = replica[0,replica.index(':')]
                activereplicalist.push(replicaip) if replicastate == "active"
                downreplicalist.push(replicaip) if replicastate == "down"
              end
              Chef::Log.info(shard)
              Chef::Log.info(activereplicalist)
              Chef::Log.info(downreplicalist)

              if activereplicalist.size < Integer(replicationFactor)
                noofoccurances = Integer(replicationFactor) - activereplicalist.size
                if Integer(maxShardsPerNode) < Integer(noofoccurances)                  
                  noofoccurances = Integer(maxShardsPerNode)
                end
                Chef::Log.info(noofoccurances)
                while Integer(noofoccurances) > 0  do
                  addreplica_url = "#{node['solr_collection_url']}?action=ADDREPLICA&collection=#{collection}&shard=#{shard}&name=#{node['ipaddress']}:8080_solr_#{collection}_#{shard}_replica_#{time}"
                  Chef::Log.info(addreplica_url)
                  addreplica_response = open(addreplica_url).read
                  noofoccurances = Integer(noofoccurances) - 1
                end
              else
                Chef::Log.info("activereplicaset size is equal or greater than replicationFactor")
              end
            end
          end
        else
          Chef::Log.error("Collections are not created. Replaced node is part of the solrcloud and cannot add as a replica.")
        end
      rescue
        raise "Exception while requesting clusterstate."
      else
        Chef::Log.info("in else block")
      ensure
        Chef::Log.info("in ensure block")
      end
    end
  end
else
  Chef::Log.info("add_replaced_replica not executed ")
end



