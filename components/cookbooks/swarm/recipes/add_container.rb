require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
container_service = node[:workorder][:services][:container][cloud_name][:ciAttributes]
container = node[:workorder][:rfcCi]

# NOTE: to use a swarm running on the same server as the inductors create file
# cat /etc/systemd/system/docker.service.d/api.conf
# [Service]
# ExecStart=
# ExecStart=/usr/bin/dockerd -H unix:///var/run/docker.sock -H tcp://127.0.0.1

docker = "docker"
docker = docker + " -H=#{container_service[:endpoint]}" if !container_service[:endpoint].empty?
Chef::Log.debug("DOCKER: #{docker}")

#
# 1. construct the docker command arguments
#

#name
create = [ "service", "create", "--name=#{node[:container_name]}" ]

#env
env = container[:ciAttributes][:env]
JSON.parse(env).each { |key, value| create.push("-e=\"#{key}=#{value}\"") } if !env.empty?

#ports
ports = container[:ciAttributes][:ports]
JSON.parse(ports).each { |key, value| create.push("-p=#{value}") } if !ports.empty?

#image
create.push("#{node[:image_name]}")

#command
create.push(container[:ciAttributes][:command])

#args
args = container[:ciAttributes][:args]
create.push(JSON.parse(args)) if !args.empty?

Chef::Log.debug("CREATE: #{docker} #{create.join(' ')}")

# inspect line
inspect = "service inspect #{node[:container_name]}"
Chef::Log.debug("INSPECT: #{docker} #{inspect}")


#
# 2. here we go, check if the service is there and if not create a new one
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
      else
        # create new service
        result = `#{docker} #{create.join(' ')} 2>&1`.chomp
        if $?.success?
          Chef::Log.info("Created container instance #{result}")
          #node.set[:container_id] = result
        else
          Chef::Log.fatal!(result)
        end
      end
    else
      # something went wrong with the get call
      Chef::Log.fatal!(service.inspect)
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
      if $?.success? && running.to_i == 1
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
