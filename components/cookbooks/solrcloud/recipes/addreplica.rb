#
# Cookbook Name :: solrcloud
# Recipe :: addReplica.rb
#
# The recipie adds replica to the solr cloud.
#

include_recipe 'solrcloud::default'

args = ::JSON.parse(node.workorder.arglist)
collection_name = args["PhysicalCollectionName"]
shard_name = args["ShardName"]
time = Time.now.getutc.to_i

activereplicalist = ''
downreplicalist = ''

if (!node['zk_select'].include? "Embedded") && (node['solr_version'].start_with? "4.")
	if (!"#{collection_name}".empty?) && (!"#{shard_name}".empty?)
    	request_url = "http://#{node['ipaddress']}:8080/#{node['clusterstatus']['uri']}"
    	response = open(request_url).read
    	jsonresponse = JSON.parse(response)
		Chef::Log.info(request_url)

		if (!jsonresponse["cluster"]["collections"].empty?) && (!jsonresponse["cluster"]["collections"]["#{collection_name}"].empty?)
      		replicaip = '';
      		maxShardsPerNode = jsonresponse["cluster"]["collections"]["#{collection_name}"]["maxShardsPerNode"]
            replicationFactor = jsonresponse["cluster"]["collections"]["#{collection_name}"]["replicationFactor"]
      		shardList = jsonresponse["cluster"]["collections"]["#{collection_name}"]["shards"].keys
 
            maxNodes = 0
            shardList.each do |shard|
            	shardstate = jsonresponse["cluster"]["collections"]["#{collection_name}"]["shards"][shard]["state"]
				if shardstate == "active"
					activereplicalist = Array.new()
					replicaList = jsonresponse["cluster"]["collections"]["#{collection_name}"]["shards"][shard]["replicas"].keys
					replicaList.each do |replica|
						replicastate = jsonresponse["cluster"]["collections"]["#{collection_name}"]["shards"][shard]["replicas"][replica]["state"]
						replicaip = replica[0,replica.index(':')]

						if (replicastate == "active") && (replicaip == "#{node['ipaddress']}")
							maxNodes = maxNodes + 1
						end
          			end
				end
            end


			if maxNodes < Integer(maxShardsPerNode)
				shardstate = jsonresponse["cluster"]["collections"]["#{collection_name}"]["shards"][shard_name]["state"]
				if shardstate == "active"
					activereplicalist = Array.new()
					downreplicalist = Array.new()

					replicaList = jsonresponse["cluster"]["collections"]["#{collection_name}"]["shards"][shard_name]["replicas"].keys
					replicaList.each do |replica|						
						replicastate = jsonresponse["cluster"]["collections"]["#{collection_name}"]["shards"][shard_name]["replicas"][replica]["state"]
						replicaip = replica[0,replica.index(':')]
						activereplicalist.push(replicaip) if replicastate == "active"
						downreplicalist.push(replicaip) if replicastate == "down"
	          		end

	          		if activereplicalist.size < Integer(replicationFactor)
	          			if (!downreplicalist.include? "#{node['ipaddress']}")
	          				begin
	          					Chef::Log.info("#{node['solr_collection_url']}?action=ADDREPLICA&collection=#{collection_name}&shard=#{shard_name}&name=#{node['ipaddress']}:8080_solr_#{collection_name}_#{shard_name}_replica_#{time}")
								bash 'add_replica' do
							    	user "#{node['solr']['user']}"
							    	code <<-EOH
							    		curl '#{node['solr_collection_url']}?action=ADDREPLICA&collection=#{collection_name}&shard=#{shard_name}&name=#{node['ipaddress']}:8080_solr_#{collection_name}_#{shard_name}_replica_#{time}'
							    	EOH
							    	not_if { "#{collection_name}".empty? }
							  	end
							rescue
								Chef::Log.error("Failed to add replica. Collection '#{collection_name}' may not exists.")
							ensure
								puts "End of add_replica execution."
							end
						else
							Chef::Log.info("Cannot add the node in down state as a Replica")
	          			end
	          		else
	          			Chef::Log.info("Shard has required number of replicas")
	          		end
				end
			else
				Chef::Log.info("This node has already been added as a replica")
			end
	    end
	else
		Chef::Log.error("Both Collection Name & Shard Name parameters are required.")
	end
else
	Chef::Log.warn("This feature is not supported for solr-5.x.x,solr-6.x.x versions and embedded zookeeper mode.")
end





