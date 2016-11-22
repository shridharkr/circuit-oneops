require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
container_service = node[:workorder][:services][:container][cloud_name][:ciAttributes]
set = node[:workorder][:rfcCi]

docker = "docker"
docker = docker + " -H=#{container_service[:endpoint]}" if !container_service[:endpoint].empty?
Chef::Log.debug("DOCKER: #{docker}")

#
# 1. construct the service command arguments to scale deployment
# service scale <container_name>=<replicas>
#

ruby_block "scale #{node[:container_name]}" do
  block do
    replicas = set[:ciAttributes][:replicas]
    service_scale = "service scale #{node[:container_name]}=#{replicas} 2>&1"
    Chef::Log.info(service_scale)
    result = `#{docker} #{service_scale}`
    if $?.success?
      Chef::Log.info(result)
    else
      Chef::Log.fatal!(result)
    end
  end
end

# TODO check if all replicas are in ready state before proceeding

inspect = "service inspect #{node[:container_name]}"
Chef::Log.debug("INSPECT: #{docker} #{inspect}")

ruby_block "get published port for #{node[:container_name]}" do
  block do

    # ports
    service = JSON.parse(`#{docker} #{inspect}`)
    Chef::Log.debug("ports: #{service.first['Endpoint']['Ports']}")
    ports = {}
    service.first['Endpoint']['Ports'].each do |service_port|
      internal_port = service_port['TargetPort']
      ports[internal_port] = service_port['PublishedPort'].to_s
    end
    puts "***RESULT:ports="+JSON.generate(ports)

    # nodes
    nodes = Array.new
    nodes_list = `#{docker} node ls | grep -v ID`
    nodes_list.gsub!(/\r\n?/, "\n")
    nodes_list.each_line do |node|
      node_id = node.gsub(/\s+/m, ' ').strip.split(" ").first
      address = `#{docker} node inspect --format '{{ .ManagerStatus.Addr }}' #{node_id}`.split(':').first
      Chef::Log.debug("node: #{address}")
      nodes.push(address) if address =~ /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/
    end
    puts "***RESULT:nodes="+JSON.generate(nodes)

  end
end
