require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
container_service = node[:workorder][:services][:container][cloud_name][:ciAttributes]
replication = node[:workorder][:rfcCi]

#
# 1. construct the kubectl command arguments to scale deployment
# kubectl scale deployment <container_name> --replicas=N
#

ruby_block "scale #{node[:container_name]}" do
  block do
    replicas = replication[:ciAttributes][:replicas]
    kubectl_scale = "kubectl scale deployment #{node[:container_name]} --replicas=#{replicas} 2>&1"
    Chef::Log.info(kubectl_scale)
    result = `#{kubectl_scale}`
    if $?.success?
      Chef::Log.info(result)
    else
      Chef::Log.fatal!(result)
    end
  end
end
# TODO check if all replicas are in ready state before proceeding

#
# 2. construct the kubectl command arguments to expose as external service
# kubectl expose deployment <container_name> --type="LoadBalancer"
#

ruby_block "expose service #{node[:container_name]}" do
  block do
    kubectl_expose = "kubectl expose deployment #{node[:container_name]} --type=\"NodePort\" 2>&1"
    Chef::Log.info(kubectl_expose)
    result = `#{kubectl_expose}`
    Chef::Log.info(result)
    
    # ports
    service = JSON.parse(`kubectl get service #{node[:container_name]} -o json`)
    ports = {}
    service['spec']['ports'].each do |service_port|
      internal_port = service_port['port']
      ports[internal_port] = service_port['nodePort'].to_s
    end       
    puts "***RESULT:ports="+JSON.generate(ports)

    
    # nodes
    nodes_result = JSON.parse(`kubectl get nodes -o json`)
    nodes = []
    nodes_result['items'].each do |item|
      addresses = item['status']['addresses']
      puts "addrs: #{addresses}"
      addresses.each do |addr|
        next unless addr['type'] == 'InternalIP'
        nodes.push(addr['address'])
      end
    end       
    puts "***RESULT:nodes="+JSON.generate(nodes)
    
        
  end
end
