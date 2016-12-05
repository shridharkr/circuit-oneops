require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
container_service = node[:workorder][:services][:container][cloud_name][:ciAttributes]
set = node[:workorder][:rfcCi]

#
# 1. construct the kubectl command arguments to scale deployment
# kubectl scale deployment <container_name> --replicas=N
#

ruby_block "scale #{node[:container_name]}" do
  block do
    kubectl_scale = "kubectl scale deployment #{node[:container_name]} --replicas=1 2>&1"
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

ruby_block "delete service #{node[:service_name]}" do
  block do
    kubectl_expose = "kubectl delete service #{node[:service_name]} 2>&1"
    Chef::Log.info(kubectl_expose)
    result = `#{kubectl_expose}`
    Chef::Log.info(result)
  end
end
