# **Rubocop Suppression**
# rubocop:disable LineLength
require File.expand_path('../../../azure/libraries/utils.rb', __FILE__)
require File.expand_path('../../libraries/application_gateway.rb', __FILE__)
require File.expand_path('../../exceptions/gateway_exception.rb', __FILE__)
require File.expand_path('../../../azure/libraries/public_ip.rb', __FILE__)
require File.expand_path('../../../azure/libraries/virtual_network.rb', __FILE__)

require 'azure_mgmt_network'
require 'rest-client'
require 'chef'
require 'json'
require 'base64'

::Chef::Recipe.send(:include, Utils)
::Chef::Recipe.send(:include, AzureNetwork)
::Chef::Recipe.send(:include, Azure::ARM::Network)
::Chef::Recipe.send(:include, Azure::ARM::Network::Models)

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'

include_recipe 'azuredns::get_azure_token'

token = node['azure_rest_token']

def get_private_ip_address(resource_group_name, ag_name, subscription_id, token)
  resource_url = "https://management.azure.com/subscriptions/#{subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.Network/applicationGateways/#{ag_name}?api-version=2016-03-30"
  dns_response = RestClient.get(
      resource_url,
      accept: 'application/json',
      content_type: 'application/json',
      authorization: token
  )
  Chef::Log.info("Azuregateway::Application Gateway - API response is #{dns_response}")
  dns_hash = JSON.parse(dns_response)
  Chef::Log.info("Azuregateway::Application Gateway - #{dns_hash}")
  dns_hash['properties']['frontendIPConfigurations'][0]['properties']['privateIPAddress']

rescue RestClient::Exception => e
  if e.http_code == 404
    Chef::Log.info('Azuregateway::Application Gateway doesn not exist')
  else
    puts "***FAULT:Message=#{e.message}"
    puts "***FAULT:Body=#{e.http_body}"
    raise GatewayException.new(e.message)
  end
rescue => e
  msg = "Exception trying to parse response: #{dns_response}"
  puts "***FAULT:FATAL=#{msg}"
  Chef::Log.error("Azuregateway::Add - Exception is: #{e.message}")
  raise GatewayException.new(msg)
end

def get_compute_nodes
  compute_nodes = []
  compute_list = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Compute/ }
  if compute_list
    # Build compute nodes to load balance
    compute_list.each do |compute|
      compute_nodes.push(compute[:ciAttributes][:private_ip])
    end
  end
  compute_nodes
end

def get_credentials(tenant_id, client_id, client_secret)
  # Create authentication objects
  token_provider = MsRestAzure::ApplicationTokenProvider.new(tenant_id, client_id, client_secret)
  if !token_provider.nil?
    MsRest::TokenCredentials.new(token_provider)
  else
    msg = 'Could not retrieve azure credentials'
    Chef::Log.error(msg)
    puts "***FAULT:FATAL=#{msg}"
    raise GatewayException.new(msg)
  end
rescue MsRestAzure::AzureOperationError
  msg = 'Error acquiring authentication token from azure'
  Chef::Log.error(msg)
  raise GatewayException.new(msg)
end

def get_public_ip(location, timeout = 5)
  pip_address_props = PublicIpAddressPropertiesFormat.new
  pip_address_props.idle_timeout_in_minutes = timeout
  pip_address_props.public_ipallocation_method = IpAllocationMethod::Dynamic
  public_ip = PublicIpAddress.new
  public_ip.location = location
  public_ip.properties = pip_address_props
  public_ip
end

def add_gateway_subnet_to_vnet(virtual_network, gateway_subnet_address, gateway_subnet_name)
  if virtual_network.properties.subnets.count > 1

    virtual_network.properties.subnets.each do |subnet|
      if subnet.name == gateway_subnet_name
        msg = 'No need to add Gateway subnet. Gateway subnet already exist...'
        puts msg
        virtual_network
      end
    end
  end

  subnet_properties = Azure::ARM::Network::Models::SubnetPropertiesFormat.new
  subnet_properties.address_prefix = gateway_subnet_address

  subnet = Azure::ARM::Network::Models::Subnet.new
  subnet.name = gateway_subnet_name
  subnet.properties = subnet_properties

  virtual_network.properties.subnets.push(subnet)
  virtual_network
end

cloud_name = node.workorder.cloud.ciName
ag_service = nil
if !node.workorder.services['lb'].nil? && !node.workorder.services['lb'][cloud_name].nil?
  ag_service = node.workorder.services['lb'][cloud_name]
end

if ag_service.nil?
  Chef::Log.error('missing application gateway service')
  exit 1
end

platform_name = node.workorder.box.ciName
environment_name = node.workorder.payLoad.Environment[0]['ciName']
assembly_name = node.workorder.payLoad.Assembly[0]['ciName']
org_name = node.workorder.payLoad.Organization[0]['ciName']
security_group = "#{environment_name}.#{assembly_name}.#{org_name}"
resource_group_name = node['platform-resource-group']
subscription_id = ag_service[:ciAttributes]['subscription']
location = ag_service[:ciAttributes][:location]

asmb_name = assembly_name.gsub(/-/, '').downcase
plat_name = platform_name.gsub(/-/, '').downcase
env_name = environment_name.gsub(/-/, '').downcase
ag_name = "ag-#{plat_name}"

tenant_id = ag_service[:ciAttributes][:tenant_id]
client_id = ag_service[:ciAttributes][:client_id]
client_secret = ag_service[:ciAttributes][:client_secret]

credentials = get_credentials(tenant_id, client_id, client_secret)
application_gateway = AzureNetwork::Gateway.new(resource_group_name, ag_name, credentials, subscription_id)

Chef::Log.info("Cloud Name: #{cloud_name}")
Chef::Log.info("Org: #{org_name}")
Chef::Log.info("Assembly: #{asmb_name}")
Chef::Log.info("Platform: #{platform_name}")
Chef::Log.info("Environment: #{env_name}")
Chef::Log.info("Location: #{location}")
Chef::Log.info("Security Group: #{security_group}")
Chef::Log.info("Resource Group: #{resource_group_name}")
Chef::Log.info("Application Gateway: #{ag_name}")

# ===== Create a Application Gateway =====
#   # AG Creation Steps
#
#   # 1 - Create public IP
#   # 2 - Create Gateway Ip Configurations
#   # 3 - Create backend address pool
#   # 4 - Create http settings
#   # 5 - Create FrontendIPConfig
#   # 6 - Create SSL Certificate
#   # 7 - Listener
#   # 8 - Routing rule, SKU
#   # 9 - Create Application Gateway

begin

  public_ip = nil
  vnet = nil
  master_rg = nil

  # Determine if express route is enabled
  express_route_enabled = true
  if ag_service[:ciAttributes][:express_route_enabled].nil?
    # We cannot assume express route is enabled if it is not set
    express_route_enabled = false
  elsif ag_service[:ciAttributes][:express_route_enabled] == 'false'
    express_route_enabled = false
  end

  vnet_obj = AzureNetwork::VirtualNetwork.new(credentials, subscription_id)

  if express_route_enabled
    vnet_name = ag_service[:ciAttributes][:network]
    master_rg = ag_service[:ciAttributes][:resource_group]
    vnet_obj.name = vnet_name
    vnet = vnet_obj.get(master_rg)

    if vnet.nil?
      msg = "Could not retrieve vnet '#{vnet_name}' from express route"
      Chef::Log.error(msg)
      puts "***FAULT:FATAL=#{msg}"
      raise GatewayException.new(msg)
    end
    vnet = vnet.body
    if vnet.properties.subnets.count < 1
      msg = "VNET '#{vnet_name}' does not have subnets"
      Chef::Log.error(msg)
      puts "***FAULT:FATAL=#{msg}"
      raise GatewayException.new(msg)
    end

  else
    nameutil = Utils::NameUtils.new
    public_ip_name = nameutil.get_component_name('ag_publicip', node['workorder']['rfcCi']['ciId'])
    public_ip_address = get_public_ip(location)
    public_ip_obj = AzureNetwork::PublicIp.new(credentials, subscription_id)
    public_ip = public_ip_obj.create_update(resource_group_name, public_ip_name, public_ip_address)
    vnet_name = 'vnet_' + resource_group_name
    vnet_obj.name = vnet_name
    vnet = vnet_obj.get(resource_group_name)
    vnet = vnet.body
  end

  gateway_subnet_address = ag_service[:ciAttributes][:gateway_subnet_address]
  gateway_subnet_name = 'GatewaySubnet'

  # Add a subnet for Gateway
  vnet = add_gateway_subnet_to_vnet(vnet, gateway_subnet_address, gateway_subnet_name)
  rg_name = master_rg.nil? ? resource_group_name : master_rg
  vnet = vnet_obj.create_update(rg_name, vnet)
  vnet = vnet.body
  gateway_subnet = nil
  vnet.properties.subnets.each do |subnet|
    if subnet.name == gateway_subnet_name
      gateway_subnet = subnet
      break
    end
  end

  # Application Gateway configuration
  application_gateway.set_gateway_configuration(gateway_subnet)

  # Backend Address Pool
  backend_ip_address_list = get_compute_nodes
  application_gateway.set_backend_address_pool(backend_ip_address_list)

  # Gateway Settings
  data = ''
  password = ''
  ssl_certificate_exist = false
  certs = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Certificate/ }
  certs.each do |cert|
    if !cert[:ciAttributes][:pfx_enable].nil? && cert[:ciAttributes][:pfx_enable] == 'true'
      data = cert[:ciAttributes][:ssl_data]
      password = cert[:ciAttributes][:ssl_password]
      ssl_certificate_exist = true
    end
  end

  enable_cookie = true
  if ag_service[:ciAttributes][:cookies_enabled].nil?
    enable_cookie = false
  elsif ag_service[:ciAttributes][:cookies_enabled] == 'false'
    enable_cookie = false
  end

  # Cookies must be enabled in case of SSL offload.
  enable_cookie = ssl_certificate_exist == true ? true : enable_cookie
  application_gateway.set_https_settings(enable_cookie)

  # Gateway Front Port
  application_gateway.set_gateway_port(ssl_certificate_exist)

  # Gateway Frontend IP Configuration
  application_gateway.set_frontend_ip_config(public_ip, gateway_subnet)

  # Gateway SSL Certificate
  if ssl_certificate_exist
    if data == '' || password == ''
      msg = "PFX Data or Password is nil or empty. Data = #{data} - Password = #{password}"
      puts msg
      raise GatewayException.new(msg)
    end
    application_gateway.set_ssl_certificate(data, password)
  end

  # Gateway Listener
  application_gateway.set_listener(ssl_certificate_exist)

  # Gateway Request Route Rule
  application_gateway.set_gateway_request_routing_rule

  # Gateway SKU
  sku_name = ag_service[:ciAttributes][:gateway_size]
  application_gateway.set_gateway_sku(sku_name)

  # Create Gateway Object
  gateway = application_gateway.get_gateway(location, ssl_certificate_exist)

  start_time = Time.now.to_i

  gateway_result = application_gateway.create_or_update(gateway)
  end_time = Time.now.to_i
  duration = end_time - start_time
  puts("Application Gateway created in #{duration} seconds.")
  if gateway_result.nil?
    # Application Gateway was not created. Exit with error
    msg = "Application Gateway '#{ag_name}' could not be created"
    puts("***FAULT:FATAL=#{msg}")
    raise GatewayException.new(msg)
  else
    ag_ip = nil
    if express_route_enabled
      ag_ip = get_private_ip_address(resource_group_name, ag_name, subscription_id, token)
    else
      ag_ip = public_ip.properties.ip_address
    end

    if ag_ip.nil? || ag_ip == ''
      msg = "Application Gateway '#{gateway_result.name}' NOT configured with IP"
      puts("***FAULT:FATAL=#{msg}")
      raise GatewayException.new(msg)
    else
      msg = "AzureAG IP: #{ag_ip}"
      Chef::Log.info(msg)
      node.set[:azure_ag_ip] = ag_ip
    end
  end
rescue => e
  puts 'Error creating Application Gateway.'
  puts e.message
  puts e.backtrace
  raise GatewayException.new(e.message)
end
