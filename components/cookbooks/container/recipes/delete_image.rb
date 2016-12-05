rfcCi = node['workorder']['rfcCi']
container = rfcCi["ciAttributes"]

# cloud_name = node.workorder.cloud.ciName
#
# cloud_service = nil
# if !node.workorder.services["registry"].nil? &&
#   !node.workorder.services["registry"][cloud_name].nil?
#   cloud_service = node.workorder.services["registry"][cloud_name]
# end
#
# if cloud_service.nil?
#   Chef::Log.fatal!("no registry cloud service defined. services: "+node.workorder.services.inspect)
# end
#
# Chef::Log.info("Registry Cloud Service: #{cloud_service[:ciClassName]}")

docker_image = "docker -H=127.0.0.1 rmi #{node[:image_name]}"

# rmi
ruby_block "remove image #{node[:image_name]}" do
  block do
    Chef::Log.info(docker_image)
    result = `#{docker_image} 2>&1`
    if $?.success?
      Chef::Log.info(result)
    else
      Chef::Log.fatal!(result)
    end
  end
end

# TODO add docker delete in registry service
