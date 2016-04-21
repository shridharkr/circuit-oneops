require File.expand_path('../../../azure/libraries/utils.rb', __FILE__)
require File.expand_path('../../../azure/libraries/public_ip.rb', __FILE__)
require File.expand_path('../../../azure/libraries/azure_utils.rb', __FILE__)
require File.expand_path('../../../azure_base/libraries/logger.rb', __FILE__)
require File.expand_path('../../../azure_lb/libraries/load_balancer', __FILE__)

require 'azure_mgmt_network'

::Chef::Recipe.send(:include, Utils)
::Chef::Recipe.send(:include, AzureCommon)
::Chef::Recipe.send(:include, AzureNetwork)


#set the proxy if it exists as a cloud var
AzureCommon::AzureUtils.set_proxy(node.workorder.payLoad.OO_CLOUD_VARS)

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'

cloud_name = node.workorder.cloud.ciName
lb_service = nil
if !node.workorder.services["lb"].nil? && !node.workorder.services["lb"][cloud_name].nil?
  lb_service = node.workorder.services["lb"][cloud_name]
end

if lb_service.nil?
  OOLog.fatal("Missing lb service! Cannot continue.")
end

tenant_id = lb_service[:ciAttributes][:tenant_id]
client_id = lb_service[:ciAttributes][:client_id]
client_secret = lb_service[:ciAttributes][:client_secret]
subscription_id = lb_service[:ciAttributes][:subscription]
#Determine if express route is enabled
# xpress_route_enabled = true
# if lb_service[:ciAttributes][:express_route_enabled].nil?
#   #We cannot assume express route is enabled if it is not set
#   xpress_route_enabled = false
# elsif lb_service[:ciAttributes][:express_route_enabled] == "false"
#   xpress_route_enabled = false
# end



platform_name = node.workorder.box.ciName
resource_group_name = node['platform-resource-group']
# environment_name = node.workorder.payLoad.Environment[0]["ciName"]
# assembly_name = node.workorder.payLoad.Assembly[0]["ciName"]
# org_name = node.workorder.payLoad.Organization[0]["ciName"]
# security_group = "#{environment_name}.#{assembly_name}.#{org_name}"
# location = lb_service[:ciAttributes][:location]


# asmb_name = assembly_name.gsub(/-/, "").downcase
# env_name = environment_name.gsub(/-/, "").downcase
plat_name = platform_name.gsub(/-/, "").downcase
lb_name = "lb-#{plat_name}"

nameutil = Utils::NameUtils.new()
public_ip_name = nameutil.get_component_name("lb_publicip", node.workorder.rfcCi.ciId)


# OOLog.info("Cloud Name: #{cloud_name}")
# OOLog.info("Org: #{org_name}")
# OOLog.info("Assembly: #{asmb_name}")
# OOLog.info("Platform: #{platform_name}")
# OOLog.info("Environment: #{env_name}")
# OOLog.info("Location: #{location}")
# OOLog.info("Security Group: #{security_group}")
# OOLog.info("Resource Group: #{resource_group_name}")
# OOLog.info("Load Balancer: #{lb_name}")

credentials = AzureCommon::AzureUtils.get_credentials(tenant_id, client_id, client_secret)

lb_svc = AzureNetwork::LoadBalancer.new(credentials, subscription_id)
begin
  lb_svc.delete(resource_group_name, lb_name)
rescue Exception => e
  OOLog.fatal(e.message)
end

pip_svc = AzureNetwork::PublicIp.new(credentials, subscription_id)
begin
  pip_svc.delete(resource_group_name, public_ip_name)
rescue Exception => e
  OOLog.fatal(e.message)
end
