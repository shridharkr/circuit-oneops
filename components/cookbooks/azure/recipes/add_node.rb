require File.expand_path('../../libraries/utils.rb', __FILE__)
require 'azure_mgmt_compute'
require 'azure_mgmt_network'

::Chef::Recipe.send(:include, Utils)
::Chef::Recipe.send(:include, Azure::ARM::Compute)
::Chef::Recipe.send(:include, Azure::ARM::Compute::Models)
::Chef::Recipe.send(:include, Azure::ARM::Network)
::Chef::Recipe.send(:include, Azure::ARM::Network::Models)

total_start_time = Time.now.to_i

cloud_name = node['workorder']['cloud']['ciName']
Chef::Log.info("Cloud Name: #{cloud_name}")
compute_service = node['workorder']['services']['compute'][cloud_name]['ciAttributes']
express_route_enabled = compute_service['express_route_enabled']

Chef::Log.info("Subscription ID: #{compute_service['subscription']}")

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'

# invoke recipe to get credentials
include_recipe "azure::get_credentials"

# invoke recipe to build the OS profile
include_recipe "azure::build_os_profile_for_add_node"

# invoke recipe to build the hardware profile
include_recipe "azure::build_hardware_profile_for_add_node"

# invoke recipe to build the storage profile
include_recipe "azure::build_storage_profile_for_add_node"

# invoke recipe to build the network profile
include_recipe "azure::build_network_profile_for_add_node"

# get the availability set to use
include_recipe "azure::get_availability_set"

# create the VM in the platform specific resource group and availability set
client = ComputeManagementClient.new(node['azureCredentials'])
client.subscription_id = compute_service['subscription']

# Create a model for new virtual machine
props = VirtualMachineProperties.new

props.os_profile = node['osProfile']
props.hardware_profile = node['hardwareProfile']
props.storage_profile = node['storageProfile']
props.network_profile = node['networkProfile']
props.availability_set = node['availability_set']

params = VirtualMachine.new
params.type = 'Microsoft.Compute/virtualMachines'
params.properties = props
params.location = compute_service['location']
begin
  start_time = Time.now.to_i
  Chef::Log.info("Creating New Azure VM :" + node['server_name'])
  # create the VM in the platform resource group
  vm_promise = client.virtual_machines.create_or_update(node['platform-resource-group'], node['server_name'], params)
  my_new_vm = vm_promise.value!
  end_time = Time.now.to_i
  duration = end_time - start_time
  Chef::Log.info("Azure VM created in #{duration} seconds")
	Chef::Log.info("New VM: #{my_new_vm.body.name} CREATED!!!")
  puts "***RESULT:instance_id="+my_new_vm.body.id
rescue MsRestAzure::AzureOperationError => e
  puts '***FAULT:FATAL=creating a VM in resource group: ' + node['platform-resource-group']
  Chef::Log.error("Error Body: #{e.body}")
  e = Exception.new('no backtrace')
  e.set_backtrace('')
  raise e
rescue Exception => ex
  puts "***FAULT:FATAL=#{ex.message}"
  ex = Exception.new('no backtrace')
  ex.set_backtrace('')
  raise ex
end

if express_route_enabled == 'false'
  networkclient = NetworkResourceProviderClient.new(node['azureCredentials'])
  networkclient.subscription_id = compute_service['subscription']
  nameutil = Utils::NameUtils.new()
  public_ip_name = nameutil.get_component_name("publicip",node['workorder']['rfcCi']['ciId'])
  Chef::Log.info("public ip name: #{public_ip_name }")
  Chef::Log.info("RG Name: #{node['platform-resource-group']}")
begin
  promise = networkclient.public_ip_addresses.get(node['platform-resource-group'], public_ip_name)
  details = promise.value!
  obj=JSON.parse(details.response.body)
  Chef::Log.info("public ip found:"+ obj['properties']['ipAddress'] )
  puts "***RESULT:public_ip="+obj['properties']['ipAddress']
  # need to add public ip as the dns record for the dns records later.
  # if the LB exists, it will be overwritten with the LB public ip.
  puts "***RESULT:dns_record="+obj['properties']['ipAddress']
  node.set['ip'] = obj['properties']['ipAddress']
rescue MsRestAzure::AzureOperationError => e
  puts '***FAULT:FATAL=creating a public IP in resource group: ' + node['platform-resource-group']
  Chef::Log.error("Error Body: #{e.body}")
  Chef::Log.error("Error retrieving public ip address")
  e = Exception.new('no backtrace')
  e.set_backtrace('')
  raise e
rescue Exception => ex
  puts "***FAULT:FATAL=#{ex.message}"
  ex = Exception.new('no backtrace')
  ex.set_backtrace('')
  raise ex
end
end

#include_recipe "azure::format_data_disk"
include_recipe "compute::ssh_port_wait"

rfcCi = node["workorder"]["rfcCi"]
nsPathParts = rfcCi["nsPath"].split("/")
customer_domain = node["customer_domain"]
owner = node.workorder.payLoad.Assembly[0].ciAttributes["owner"] || "na"
node.set["max_retry_count_add"] = 30

mgmt_url = "https://"+node.mgmt_domain
if node.has_key?("mgmt_url") && !node.mgmt_url.empty?
  mgmt_url = node.mgmt_url
end

metadata = {
  "owner" => owner,
  "mgmt_url" =>  mgmt_url,
  "organization" => node.workorder.payLoad[:Organization][0][:ciName],
  "assembly" => node.workorder.payLoad[:Assembly][0][:ciName],
  "environment" => node.workorder.payLoad[:Environment][0][:ciName],
  "platform" => node.workorder.box.ciName,
  "component" => node.workorder.payLoad[:RealizedAs][0][:ciId].to_s,
  "instance" => node.workorder.rfcCi.ciId.to_s
}

puts "***RESULT:metadata="+JSON.dump(metadata)
total_end_time = Time.now.to_i
duration = total_end_time - total_start_time
Chef::Log.info("Total Time for azure::add_node recipe is #{duration} seconds")
