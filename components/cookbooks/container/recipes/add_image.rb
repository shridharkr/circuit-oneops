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

docker_build = "docker -H=127.0.0.1 build -q --force-rm --tag #{node[:image_name]}"
if container['url'].empty?
  if container['dockerfile'].empty?
    Chef::Log.fatal!("Either URL or Dockerfile content must be specified to proceed")
  else
    Chef::Log.info("Found content for Dockerfile and will use it to build image")
    dockerfile = "#{Chef::Config['file_cache_path']}/Dockerfile-#{rfcCi['ciId']}"
    # create temporary file
    file "#{dockerfile}" do
      content container['dockerfile']
    end
    # setup docker cli
    docker_build += " - < #{dockerfile}"
  end
else
  if container['dockerfile'].empty?
    Chef::Log.info("I will use the Dockerfile inside the URL context #{conteiner['url']} to build image")
    docker_build += container['url']
  else
    Chef::Log.info("Found content for Dockerfile and URL context and will use both to build image")
    docker_build += " -f #{dockerfile} #{container['url']}"
  end
end

# build
ruby_block "build image for #{node[:container_name]}" do
  block do
    Chef::Log.info(docker_build)
    result = `#{docker_build} 2>&1`
    if $?.success?
      Chef::Log.info(result)
    else
      Chef::Log.fatal!(result)
    end
  end
end

# TODO add docker push with registry service
