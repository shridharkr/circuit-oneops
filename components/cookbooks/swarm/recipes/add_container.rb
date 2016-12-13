require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
container_service = node[:workorder][:services][:container][cloud_name][:ciAttributes]
container = node[:workorder][:rfcCi]

# NOTE: to use a swarm running on the same server as the inductors create_args file
# cat /etc/systemd/system/docker.service.d/api.conf
# [Service]
# ExecStart=
# ExecStart=/usr/bin/dockerd -H unix:///var/run/docker.sock -H tcp://127.0.0.1

docker = "docker"
docker = docker + " -H=#{container_service[:endpoint]}" if !container_service[:endpoint].empty?
Chef::Log.debug("DOCKER: #{docker}")

#
# 1. construct the docker service command arguments
#
env = JSON.parse(container[:ciAttributes][:env])
ports = JSON.parse(container[:ciAttributes][:ports]).values.sort.uniq
args = JSON.parse(container[:ciAttributes][:args])

# create
create_args = [ "--name=#{node[:container_name]}" ]
env.each { |key, value| create_args.push("-e=\"#{key}=#{value}\"") } if !env.empty?
ports.each { |port| create_args.push("-p=#{port}") } if !ports.empty?
create_args.push("#{node[:image_name]}")
create_args.push(container[:ciAttributes][:command])
create_args.push(args) if !args.empty?

# update
update_args = [ "--image=#{node[:image_name]}" ]
# NOTE there seems to be a bug when adding new ports with --publish-add
if container[:ciBaseAttributes].has_key?("ports")
  old_ports = JSON.parse(container[:ciBaseAttributes][:ports]).values.sort.uniq
  (ports - old_ports).each { |port| update_args.push("--publish-add=#{port}") }
  (old_ports - ports).each { |port| update_args.push("--publish-rm=#{port}") }
end
update_args.push("#{node[:container_name]}")
# TODO diff ports, envs, args

# inspect line
inspect = "service inspect #{node[:container_name]}"
Chef::Log.debug("INSPECT: #{docker} #{inspect}")


#
# 2. here we go, check if the service is there and if not create_args a new one
#
ruby_block "container #{node[:container_name]}" do
  block do
    service = JSON.parse(`#{docker} #{inspect}`.tr("\n"," "))
    # add check for exit status
    if service && service.kind_of?(Array)
      Chef::Log.debug("SERVICE: #{service.inspect}")
      if service.size > 0
        node.set[:instance_name] = service[0]['Spec']['Name']
        Chef::Log.info("exists instance name #{node[:instance_name]}")
        # update service
        Chef::Log.info("#{docker} service update #{update_args.join(' ')}")
        result = `#{docker} service update #{update_args.join(' ')} 2>&1`.chomp
        if $?.success?
          Chef::Log.info("Updated service instance #{result}")
          #node.set[:container_id] = result
        else
          Chef::Log.error(result)
          raise
        end
      else
        # create new service
        Chef::Log.info("#{docker} service create #{create_args.join(' ')}")
        result = `#{docker} service create #{create_args.join(' ')} 2>&1`.chomp
        if $?.success?
          Chef::Log.info("Created service instance #{result}")
          #node.set[:container_id] = result
        else
          Chef::Log.error(result)
          raise
        end
      end
    else
      # something went wrong with the get call
      Chef::Log.error(service.inspect)
      raise
    end
  end
end

#
# 3. wait for the status to be Running and grab some information from the service
#
status = "service ps -f 'desired-state=running' #{node[:container_name]} | grep Running | wc -l"
Chef::Log.debug("STATUS: #{docker} #{status}")

ruby_block "container #{node[:container_name]} status" do
  block do
    retries = 0
    complete = false
    while (!complete and retries < 60)
      running = `#{docker} #{status}`.chomp
      Chef::Log.debug("RUNNING: #{running.inspect}")
      if $?.success? && running.to_i > 0
        complete = true
        Chef::Log.info("container #{node[:instance_name]} status is Running")
      else
        Chef::Log.info("container #{node[:instance_name]} status is NOT Running yet")
        retries += 1
        sleep 5
      end
    end
    if !complete
      Chef::Log.fatal!("service #{node[:instance_name]} failed to complete #{service.inspect}")
    end
  end
end
