
puts "***RESULT:node_ip=#{node.workorder.payLoad.ManagedVia[0][:ciAttributes][:private_ip]}"

if node.workorder.rfcCi.ciAttributes.endpoint_snitch !~ /PropertyFileSnitch|GossipingPropertyFileSnitch/
  Chef::Log.info("snitch: #{node.workorder.rfcCi.ciAttributes.endpoint_snitch} no topology file needed")
  return
end

# maintain the topology on updates or if its a PFS or GPFS
if (node.workorder.rfcCi.rfcAction != "add" &&
   node.workorder.rfcCi.rfcAction != "replace" &&
   node.workorder.rfcCi.ciAttributes.endpoint_snitch !~ /\.PropertyFileSnitch|\.GossipingPropertyFileSnitch/
   ) || node.workorder.rfcCi.ciAttributes.endpoint_snitch =~ /\.PropertyFileSnitch|\.GossipingPropertyFileSnitch/

  template "/opt/cassandra/conf/cassandra-topology.properties" do
    source "cassandra-topology.properties.erb"
  end
else
  execute "rm -f /opt/cassandra/conf/cassandra-topology.properties"
end

template "/opt/cassandra/conf/cassandra-rackdc.properties" do
  source "cassandra-rackdc.properties.erb"
end
