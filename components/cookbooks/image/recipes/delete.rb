# Copyright 2016, Walmart Stores, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# Cookbook Name:: image
# Recipe:: delete
#

ci = node.workorder.rfcCi
node.set[:realm] = ci.nsPath.split("/")[1..3].join("-").to_s
image_name = [node.workorder.box.ciName,ci.ciId.to_s].join("-")

cloud_name = node.workorder.cloud.ciName

cloud_service = nil
if !node.workorder.services["registry"].nil? &&
  !node.workorder.services["registry"][cloud_name].nil?
  cloud_service = node.workorder.services["registry"][cloud_name]
end

if cloud_service.nil?
  Chef::Log.info("Registry cloud service not defined. Services: "+node.workorder.services.inspect)
  node.set[:registry] = "registry:5000"
else
  Chef::Log.info("Registry cloud service: #{cloud_service[:ciClassName]}")
  # fix later
end

image = ci[:ciAttributes]

node.set[:image_name] = "#{node[:registry]}/#{node[:realm]}/#{image_name}:#{image[:tag]}"

docker_image = "docker -H=127.0.0.1 rmi #{node[:image_name]}"

# rmi
ruby_block "remove image #{node[:image_name]}" do
  block do
    sleep 5
    Chef::Log.info(docker_image)
    result = `#{docker_image} 2>&1`
    if $?.success?
      Chef::Log.info(result)
    else
      Chef::Log.error(result)
      if result.match("No such image: #{node[:image_name]}")
        Chef::Log.info("Looks like image was already deleted")
      else
        raise
      end
    end
  end
end

# TODO add docker delete in registry service
