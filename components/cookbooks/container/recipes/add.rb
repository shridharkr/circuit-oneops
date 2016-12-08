# Cookbook Name:: container
# Recipe:: add
#
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

rfcCi = node["workorder"]["rfcCi"]
nsPathParts = rfcCi["nsPath"].split("/")
container_name = node.workorder.box.ciName+'-'+nsPathParts[3]+'-'+nsPathParts[2]+'-'+nsPathParts[1]+'-'+ rfcCi["ciId"].to_s
node.set[:container_name] = container_name

cloud_name = node.workorder.cloud.ciName

cloud_service = nil
if !node.workorder.services["container"].nil? &&
  !node.workorder.services["container"][cloud_name].nil?
  cloud_service = node.workorder.services["container"][cloud_name]
end

if cloud_service.nil?
  Chef::Log.fatal("no container cloud service defined. services: "+node.workorder.services.inspect)
end

Chef::Log.info("Container Cloud Service: #{cloud_service[:ciClassName]}")

# check if we need to build image
container = rfcCi[:ciAttributes]
case container[:image_type]
when 'registry'
  Chef::Log.info("Using image #{container[:image]} from registry")
  node.set[:image_name] = container[:image]
when 'dockerfile'
  Chef::Log.info("Build image using a Dockerfile")
  node.set[:image_name] = container_name + ":" + container[:tag]
  include_recipe "container::add_image"
else
  Chef::Log.fatal!("I don't know how to deal with image type #{container[:image_type]}")
end

case cloud_service[:ciClassName].split(".").last.downcase
when /kubernetes/
  include_recipe "kubernetes::add_container"
when /swarm/
  include_recipe "swarm::add_container"
when /ecs/
  include_recipe "ecs::add_container"
else
  Chef::Log.fatal!("Container Cloud Service: #{cloud_service[:ciClassName]}")
end
