require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
container_service = node[:workorder][:services][:container][cloud_name][:ciAttributes]
container = node[:workorder][:rfcCi]

#
# 1. construct the kubectl command arguments
#

#name
kubectl = [ "run", node[:container_name] ]

#image
kubectl.push("--image=#{container[:ciAttributes][:image]}")

#env
env = container[:ciAttributes][:env]
JSON.parse(env).each { |key, value| kubectl.push("--env=\"#{key}=#{value}\"") } if !env.empty?

#ports
ports = container[:ciAttributes][:ports]
JSON.parse(ports).each { |key, value| kubectl.push("--port=#{value}") } if !ports.empty?

#command
kubectl.push(container[:ciAttributes][:command])

#args
args = container[:ciAttributes][:args]
kubectl.push(JSON.parse(args)) if !args.empty?

Chef::Log.debug("KUBECTL: #{kubectl.inspect}")

#
# 2. here we go, check if the pod is there and if not create a new one
#
ruby_block "container #{node[:container_name]}" do
  block do
    Chef::Log.info("kubectl get pods -o json -l run=#{node[:container_name]}")
    pod = JSON.parse(`kubectl get pods -o json -l run=#{node[:container_name]} 2>&1`.tr("\n"," "))
    # add check for exit status
    if pod && pod.has_key?('items')
      Chef::Log.debug("POD: #{pod.inspect}")
      if pod['items'].size > 0
        node.set[:instance_name] = pod['items'][0]['metadata']['name']
        Chef::Log.info("exists instance name #{node[:instance_name]}")
      else
        # create new pod
        result = `kubectl #{kubectl.join(' ')} 2>&1`
        Chef::Log.info(result.tr("\n"," "))
      end
    else
      # something went wrong with the get call
      Chef::Log.fatal!(pod.inspect)
    end
  end
end

#
# 3. wait for the status to be Running and grab some information from the pod
#
ruby_block "container #{node[:container_name]} status" do
  block do
    retries = 0
    complete = false
    while (!complete and retries < 60)
      pod = JSON.parse(`kubectl get pods -o json -l run=#{node[:container_name]} 2>&1`)
      if pod && pod.has_key?('items') && pod['items'].size == 1
        pod = pod['items'][0]
        status = pod['status']['phase']
        node.set[:instance_name] = pod['metadata']['name']
        case status
        when 'Running'
          complete = true
          Chef::Log.info("pod #{node[:instance_name]} status is Running")
          #puts "***RESULT:instance_name=#{node[:instance_name]}"
          #puts "***RESULT:instance_uid=#{pod['metadata']['uid']}"
          #puts "***RESULT:container_id=#{pod['status']['containerStatuses'][0]['containerID']}"
          #puts "***RESULT:public_ip=#{pod['status']['hostIP']}"
          #puts "***RESULT:private_ip=#{pod['status']['podIP']}"
        when 'Pending'
          Chef::Log.info("pod #{node[:instance_name]} status is #{status}, waiting for Running...")
          retries += 1
          sleep 5
        else
          Chef::Log.fatal!("pod #{node[:instance_name]} failed with status #{status}")
        end
      else
        # something went wrong with the get call
        Chef::Log.fatal!(pod.inspect)
      end
    end
    if !complete
      Chef::Log.fatal!("pod #{node[:instance_name]} failed to complete #{pod.inspect}")
    end
  end
end
