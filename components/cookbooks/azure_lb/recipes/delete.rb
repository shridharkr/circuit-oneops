require File.expand_path('../../../azure/libraries/utils.rb', __FILE__)
require File.expand_path('../../../azure/libraries/public_ip.rb', __FILE__)
require File.expand_path('../../../azure/libraries/azure_utils.rb', __FILE__)
require File.expand_path('../../../azure_lb/libraries/load_balancer', __FILE__)

# /opt/oneops/inductor/circuit-oneops-1/components/cookbooks/azure_lb/azure_lb/libraries/load_balancer

require 'azure_mgmt_network'

::Chef::Recipe.send(:include, Utils)
::Chef::Recipe.send(:include, AzureCommon)
::Chef::Recipe.send(:include, AzureNetwork)
# ::Chef::Recipe.send(:include, Azure::ARM::Network)
# ::Chef::Recipe.send(:include, Azure::ARM::Network::Models)

#set the proxy if it exists as a cloud var
AzureCommon::AzureUtils.set_proxy(node.workorder.payLoad.OO_CLOUD_VARS)

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'


# def delete_public_ip(credentials, subscription_id, rg_name, public_ip_name)
#   begin
#     client = NetworkResourceProviderClient.new(credentials)
#     client.subscription_id = subscription_id
#     promise = client.public_ip_addresses.delete(rg_name, public_ip_name)
#     response = promise.value!
#     result = response.body
#     return result
#   rescue  MsRestAzure::AzureOperationError =>e
#     puts("Error deleting PublicIP '#{public_ip_name}' in ResourceGroup '#{rg_name}'")
#     puts("Error Response: #{e.response}")
#     puts("Error Body: #{e.body}")
#     exit 1
#   end
# end

def delete_lb(credentials, subscription_id, rg_name, lb_name)
  begin
    client = NetworkResourceProviderClient.new(credentials)
    client.subscription_id = subscription_id
    start_time = Time.now.to_i
    promise = client.load_balancers.delete(rg_name, lb_name)
    response = promise.value!
    result = response.body
    end_time = Time.now.to_i
    duration = end_time - start_time
    Chef::Log.info("Load Balancer '#{lb_name}' deleted in #{duration} seconds")

    return result
  rescue  MsRestAzure::AzureOperationError =>e
    Chef::Log.error("Error deleting Load Balancer '#{lb_name}'")
    Chef::Log.error("Error Response: #{e.response}")
    Chef::Log.error("Error Body: #{e.body}")
    exit 1
  end
end

# ===================================================

cloud_name = node.workorder.cloud.ciName
lb_service = nil
if !node.workorder.services["lb"].nil? && !node.workorder.services["lb"][cloud_name].nil?
  lb_service = node.workorder.services["lb"][cloud_name]
end

if lb_service.nil?
  Chef::Log.error("missing lb service")
  exit 1
end

tenant_id = lb_service[:ciAttributes][:tenant_id]
client_id = lb_service[:ciAttributes][:client_id]
client_secret = lb_service[:ciAttributes][:client_secret]

#Determine if express route is enabled
xpress_route_enabled = true
if lb_service[:ciAttributes][:express_route_enabled].nil?
  #We cannot assume express route is enabled if it is not set
  xpress_route_enabled = false
elsif lb_service[:ciAttributes][:express_route_enabled] == "false"
  xpress_route_enabled = false
end


platform_name = node.workorder.box.ciName
environment_name = node.workorder.payLoad.Environment[0]["ciName"]
assembly_name = node.workorder.payLoad.Assembly[0]["ciName"]
org_name = node.workorder.payLoad.Organization[0]["ciName"]
security_group = "#{environment_name}.#{assembly_name}.#{org_name}"
resource_group_name = node['platform-resource-group']
location = lb_service[:ciAttributes][:location]
subscription_id = lb_service[:ciAttributes][:subscription]

asmb_name = assembly_name.gsub(/-/, "").downcase
plat_name = platform_name.gsub(/-/, "").downcase
env_name = environment_name.gsub(/-/, "").downcase
lb_name = "lb-#{plat_name}"

nameutil = Utils::NameUtils.new()
public_ip_name = nameutil.get_component_name("lb_publicip",node.workorder.rfcCi.ciId)


Chef::Log.info("Cloud Name: #{cloud_name}")
Chef::Log.info("Org: #{org_name}")
Chef::Log.info("Assembly: #{asmb_name}")
Chef::Log.info("Platform: #{platform_name}")
Chef::Log.info("Environment: #{env_name}")
Chef::Log.info("Location: #{location}")
Chef::Log.info("Security Group: #{security_group}")
Chef::Log.info("Resource Group: #{resource_group_name}")
Chef::Log.info("Load Balancer: #{lb_name}")

credentials = AzureCommon::AzureUtils.get_credentials(tenant_id, client_id, client_secret)

lb_svc = AzureNetwork::LoadBalancer.new(credentials, subscription_id)
# delete_lb(credentials, subscription_id, resource_group_name, lb_name)
lb_svc.delete(resource_group_name, lb_name)

pip_svc = AzureNetwork::PublicIp.new(credentials, subscription_id)
# delete_public_ip(credentials, subscription_id, resource_group_name, public_ip_name)
pip_svc.delete(resource_group_name, public_ip_name)


