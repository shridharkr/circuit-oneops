require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
container_service = node[:workorder][:services][:container][cloud_name][:ciAttributes]
container = node[:workorder][:rfcCi]

docker = "docker"
docker = docker + " -H=#{container_service[:endpoint]}" if !container_service[:endpoint].empty?
Chef::Log.debug("DOCKER: #{docker}")


ruby_block "delete service #{node[:container_name]}" do
  block do
    service_scale = "service rm #{node[:container_name]} 2>&1"
    Chef::Log.info(service_scale)
    result = `#{docker} #{service_scale}`
    if $?.success?
      Chef::Log.info(result)
    else
      Chef::Log.fatal!(result)
    end
  end
end
