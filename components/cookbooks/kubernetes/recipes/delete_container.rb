require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
container_service = node[:workorder][:services][:container][cloud_name][:ciAttributes]
container = node[:workorder][:rfcCi]

ruby_block "delete container #{node[:container_name]}" do
  block do
    kubectl = "kubectl delete deployment #{node[:container_name]} 2>&1"
    Chef::Log.info(kubectl)
    result = `#{kubectl}`
    Chef::Log.info(result)
  end
end
