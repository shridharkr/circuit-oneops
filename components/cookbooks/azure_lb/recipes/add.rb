require File.expand_path('../../../azure/libraries/utils.rb', __FILE__)
require 'azure_mgmt_compute'
require 'azure_mgmt_network'

::Chef::Recipe.send(:include, Utils)
::Chef::Recipe.send(:include, Azure::ARM::Compute)
::Chef::Recipe.send(:include, Azure::ARM::Compute::Models)
::Chef::Recipe.send(:include, Azure::ARM::Network)
::Chef::Recipe.send(:include, Azure::ARM::Network::Models)

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'

def get_credentials(lb_service)
  tenant_id = lb_service[:ciAttributes][:tenant_id]
  client_id = lb_service[:ciAttributes][:client_id]
  client_secret = lb_service[:ciAttributes][:client_secret]

  begin
    # Create authentication objects
    token_provider = MsRestAzure::ApplicationTokenProvider.new(tenant_id,client_id,client_secret)
    if token_provider != nil
      credentials = MsRest::TokenCredentials.new(token_provider)
      return credentials
    else
      msg = "Could not retrieve azure credentials"
      Chef::Log.error(msg)
      # puts "***FAULT:FATAL=#{msg}"
      raise(msg)
    end
  rescue  MsRestAzure::AzureOperationError =>e
    msg = "Error acquiring authentication token from azure"
    # puts "***FAULT:FATAL=#{msg}"
    Chef::Log.error(msg)
    raise(msg)
  end
end

def get_vnet(credentials, subscription_id, resource_group_name, vnet_name)
  begin
    client = NetworkResourceProviderClient.new(credentials)
    client.subscription_id = subscription_id
    promise = client.virtual_networks.get(resource_group_name, vnet_name)
    response = promise.value!
    result = response.body
    return result
  rescue  MsRestAzure::AzureOperationError =>e
    Chef::Log.error("Error fetching Virtual Network '#{vnet_name}' ")
    Chef::Log.error("Error Response: #{e.response}")
    Chef::Log.error("Error Body: #{e.body}")
    return nil
  end
end

def get_subnet(credentials, subscription_id, resource_group_name, vnet_name, subnet_name)
  begin
    client = NetworkResourceProviderClient.new(credentials)
    client.subscription_id = subscription_id
    promise = client.subnets.get(resource_group_name, vnet_name, subnet_name)
    response = promise.value!
    result = response.body
    return result
  rescue  MsRestAzure::AzureOperationError =>e
    Chef::Log.error("Error fetching Subnet '#{subnet_name}'")
    Chef::Log.error("Error Response: #{e.response}")
    Chef::Log.error("Error Body: #{e.body}")
    return nil
  end
end

def get_vm(credentials, subscription_id, rg_name, vm_name)
  begin
    Chef::Log.info("Fetching VM: '#{vm_name}'")
    start_time = Time.now.to_i

    client = ComputeManagementClient.new(credentials)
    client.subscription_id = subscription_id

    promise = client.virtual_machines.get(rg_name, vm_name)
    result = promise.value!
    end_time = Time.now.to_i
    duration = end_time - start_time
    Chef::Log.info("VM fetched in #{duration} seconds")

    return result.body
  rescue  MsRestAzure::AzureOperationError =>e
    Chef::Log.error("Error fetching VM: '#{vm_name}'")
    Chef::Log.error("Error Response: #{e.response}")
    Chef::Log.error("Error Body: #{e.body}")
    return nil
  end
end

def get_nic(credentials, subscription_id, resource_group_name, nic_name)
  begin
    client = NetworkResourceProviderClient.new(credentials)
    client.subscription_id = subscription_id
    promise = client.network_interfaces.get(resource_group_name, nic_name)
    response = promise.value!
    result = response.body
    return result
  rescue  MsRestAzure::AzureOperationError =>e
    Chef::Log.error("Error getting NIC '#{nic_name}'")
    Chef::Log.error("Error Response: #{e.response}")
    Chef::Log.error("Error Body: #{e.body}")
    return nil
  end
end

def get_public_ip(credentials, subscription_id, resource_group_name, public_ip_name)
  begin
    client = NetworkResourceProviderClient.new(credentials)
    client.subscription_id = subscription_id
    promise = client.public_ip_addresses.get(resource_group_name, public_ip_name)
    response = promise.value!
    result = response.body
    return result
  rescue  MsRestAzure::AzureOperationError =>e
    Chef::Log.error("Error getting public ip '#{public_ip_name}'")
    Chef::Log.error("Error Response: #{e.response}")
    Chef::Log.error("Error Body: #{e.body}")
    return nil
  end
end

def create_update_public_ip(credentials, subscription_id, location, resource_group_name, public_ip_name)
  begin
    pip_address_props = PublicIpAddressPropertiesFormat.new
    pip_address_props.idle_timeout_in_minutes = 5
    pip_address_props.public_ipallocation_method = IpAllocationMethod::Dynamic
    public_ip = PublicIpAddress.new
    public_ip.location = location
    public_ip.properties = pip_address_props


    client = NetworkResourceProviderClient.new(credentials)
    client.subscription_id = subscription_id

    start_time = Time.now.to_i
    promise = client.public_ip_addresses.begin_create_or_update(resource_group_name, public_ip_name, public_ip)
    response = promise.value!
    result = response.body
    end_time = Time.now.to_i

    duration = end_time - start_time

    Chef::Log.info("Public IP created/updated in #{duration} seconds")

    return result
  rescue  MsRestAzure::AzureOperationError =>e
    Chef::Log.error("Error creating/updating public IP '#{public_ip_name}'")
    Chef::Log.error("Error Response: #{e.response}")
    Chef::Log.error("Error Body: #{e.body}")
    exit 1
  end
end

def create_update_nic(credentials, subscription_id, location, rg_name, nic_name, net_interface_props)
  begin
    nic = NetworkInterface.new
    nic.location = location
    nic.properties = net_interface_props
    Chef::Log.info("Updating NIC '#{nic_name}' ")
    client = NetworkResourceProviderClient.new(credentials)
    client.subscription_id = subscription_id
    start_time = Time.now.to_i
    promise = client.network_interfaces.create_or_update(rg_name, nic_name, nic)
    response = promise.value!
    result = response.body
    end_time = Time.now.to_i
    duration = end_time - start_time
    Chef::Log.info("NIC '#{nic_name}' was updated in #{duration} seconds")
    return result
  rescue  MsRestAzure::AzureOperationError =>e
    Chef::Log.error("Error creating/updating NIC '#{nic_name}' ")
    Chef::Log.error("Error Response: #{e.response}")
    Chef::Log.error("Error Body: #{e.message}")
    return nil
  end
end

def create_frontend_ipconfig(subscription_id, rg_name, lb_name, frontend_name, public_ip, subnet)
  # Frontend IP configuration – a Load balancer can include one or more frontend IP addresses,
  # otherwise known as a virtual IPs (VIPs). These IP addresses serve as ingress for the traffic.
  frontend_ipconfig_props = FrontendIpConfigurationPropertiesFormat.new

  if public_ip.nil?
    frontend_ipconfig_props.subnet = subnet
    frontend_ipconfig_props.private_ipallocation_method = IpAllocationMethod::Static
  else
    frontend_ipconfig_props.public_ipaddress = public_ip
  end

  frontend_ipconfig_props.inbound_nat_rules = []
  frontend_ipconfig_props.load_balancing_rules = []


  frontend_ip = "/subscriptions/#{subscription_id}/resourceGroups/#{rg_name}/providers/Microsoft.Network/loadBalancers/#{lb_name}/frontendIPConfigurations/#{frontend_name}"
  frontend_ipconfig = FrontendIpConfiguration.new
  frontend_ipconfig.id = frontend_ip
  frontend_ipconfig.name = frontend_name
  frontend_ipconfig.properties = frontend_ipconfig_props

  return frontend_ipconfig
end

def create_backend_address_pool(subscription_id, rg_name, lb_name, backend_address_pool_name)
  # Backend address pool – these are IP addresses associated with the
  # virtual machine Network Interface Card (NIC) to which load will be distributed.
  backend_address_props = BackendAddressPoolPropertiesFormat.new
  backend_address_props.load_balancing_rules = []
  backend_address_props.backend_ipconfigurations = []

  backend_ip = "/subscriptions/#{subscription_id}/resourceGroups/#{rg_name}/providers/Microsoft.Network/loadBalancers/#{lb_name}/backendAddressPools/#{backend_address_pool_name}"
  backend_address_pool = BackendAddressPool.new
  backend_address_pool.id = backend_ip
  backend_address_pool.name = backend_address_pool_name
  backend_address_pool.properties = backend_address_props

  return backend_address_pool
end

def create_probe(subscription_id, rg_name, lb_name, probe_name, protocol, port, interval_secs, num_probes, request_path)
  # Probes – probes enable you to keep track of the health of VM instances.
  # If a health probe fails, the VM instance will be taken out of rotation automatically.
  probe_props = ProbePropertiesFormat.new
  probe_props.protocol = protocol
  probe_props.port = port   # 1 to 65535, inclusive.
  probe_props.request_path = request_path
  probe_props.number_of_probes = num_probes
  probe_props.interval_in_seconds = interval_secs
  probe_props.load_balancing_rules = []

  probe_id = "/subscriptions/#{subscription_id}/resourceGroups/#{rg_name}/providers/Microsoft.Network/loadBalancers/#{lb_name}/probes/#{probe_name}"
  probe = Probe.new
  probe.id = probe_id
  probe.name = probe_name
  probe.properties = probe_props

  return probe
end

def create_inbound_nat_rule(subscription_id, rg_name, lb_name, nat_rule_name, idle_min, protocol, frontend_port, backend_port, frontend_ipconfig, backend_ip_config)
  # Inbound NAT rules – NAT rules defining the inbound traffic flowing through the frontend IP
  # and distributed to the back end IP.
  inbound_nat_rule_props = InboundNatRulePropertiesFormat.new
  inbound_nat_rule_props.protocol = protocol
  inbound_nat_rule_props.backend_port = backend_port
  inbound_nat_rule_props.frontend_port = frontend_port
  inbound_nat_rule_props.enable_floating_ip = false
  inbound_nat_rule_props.idle_timeout_in_minutes = idle_min
  inbound_nat_rule_props.frontend_ipconfiguration = frontend_ipconfig
  inbound_nat_rule_props.backend_ipconfiguration = backend_ip_config

  nat_rule_id = "/subscriptions/#{subscription_id}/resourceGroups/#{rg_name}/providers/Microsoft.Network/loadBalancers/#{lb_name}/inboundNatRules/#{nat_rule_name}"
  in_nat_rule = InboundNatRule.new
  in_nat_rule.id = nat_rule_id
  in_nat_rule.name = nat_rule_name
  in_nat_rule.properties = inbound_nat_rule_props

  return in_nat_rule
end

def create_lb_rule(lb_rule_name, load_distribution, protocol, frontend_port, backend_port, probe, frontend_ipconfig, backend_address_pool)
  # Load Balancing Rule: a rule property maps a given frontend IP and port combination to a set
  # of backend IP addresses and port combination.
  # With a single definition of a load balancer resource, you can define multiple load balancing rules,
  # each rule reflecting a combination of a frontend IP and port and backend IP and port associated with VMs.
  lb_rule_props = LoadBalancingRulePropertiesFormat.new
  # lb_rule_props.probe = probe
  lb_rule_props.protocol = protocol
  lb_rule_props.backend_port = backend_port
  lb_rule_props.frontend_port = frontend_port
  lb_rule_props.enable_floating_ip = false
  lb_rule_props.idle_timeout_in_minutes = 5  # Default
  lb_rule_props.load_distribution = load_distribution
  lb_rule_props.backend_address_pool = backend_address_pool
  lb_rule_props.frontend_ipconfiguration = frontend_ipconfig

  lb_rule = LoadBalancingRule.new
  lb_rule.name = lb_rule_name
  lb_rule.properties = lb_rule_props

  return lb_rule
end

def create_lb_props(frontend_ip_configs, backend_address_pools, lb_rules, nat_rules, probes)
  lb_props = LoadBalancerPropertiesFormat.new
  lb_props.probes = probes
  lb_props.frontend_ipconfigurations = frontend_ip_configs # Array<FrontendIpConfiguration>
  lb_props.backend_address_pools = backend_address_pools  # Array<BackendAddressPool>
  lb_props.load_balancing_rules = lb_rules # Array<LoadBalancingRule>
  lb_props.inbound_nat_rules = nat_rules # Array<InboundNatRule>

  return lb_props
end

def create_update_lb(credentials, subscription_id, location, rg_name, lb_name, lb_props)
  begin
    lb = LoadBalancer.new
    lb.location = location
    lb.properties = lb_props

    client = NetworkResourceProviderClient.new(credentials)
    client.subscription_id = subscription_id

    promise = client.load_balancers.create_or_update(rg_name, lb_name, lb)
    response = promise.value!
    result = response.body

    return result
  rescue  MsRestAzure::AzureOperationError =>e
    Chef::Log.error("Error creating Load Balancer '#{lb_name}'")
    Chef::Log.error("Error Response: #{e.response}")
    Chef::Log.error("Error Body: #{e.body}")
    return nil
  end
end

def get_probes
  ci = {}
  if node.workorder.has_key?("rfcCi")
    ci = node.workorder.rfcCi
  else
    ci = node.workorder.ci
  end

  ecvs = Array.new
  ecvs_raw = JSON.parse(ci[:ciAttributes][:ecv_map])
  if ecvs_raw
    ecvs_raw.each do |item|
      # each item is an array
      port = item[0].to_i
      pathParts = item[1].split(' ')
      request_path = pathParts[1]

      probe_name = "Probe#{port}"
      interval_secs = 15
      num_probes = 3
      protocol = Azure::ARM::Network::Models::ProbeProtocol::Http

      ecvs.push({
                    :probe_name => probe_name,
                    :interval_secs => interval_secs,
                    :num_probes => num_probes,
                    :port => port,
                    :protocol => protocol,
                    :request_path => request_path
                })
    end
  end

  return ecvs
end

def get_listeners
  listeners = Array.new

  if node["loadbalancers"]
    raw_data = node['loadbalancers']
    raw_data.each do |listener|
      listeners.push(listener)
      Chef::Log.info("Listener '#{listener}'")
    end
  end

  return listeners
end

def get_compute_nodes
  compute_nodes = Array.new
  computes = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Compute/ }
  if computes
    #Build computes nodes to load balance
    computes.each do |compute|
      compute_nodes.push({
                             :ciId => compute[:ciId],
                             :ipaddress => compute[:ciAttributes][:private_ip],
                             :hostname => compute[:ciAttributes][:hostname],
                             :instance_id => compute[:ciAttributes][:instance_id],
                             :instance_name => compute[:ciAttributes][:instance_name],
                             :allow_port => get_allow_rule_port(compute[:ciAttributes][:allow_rules])
                         })
    end
  end

  return compute_nodes
end

def get_allow_rule_port(allow_rules)
  port = 22  #Default port
  if !allow_rules.nil?
    rulesParts = allow_rules.split(" ")
    rulesParts.each do |item|
      if item =~ /\d/
        port = item.gsub!(/\D/, "")
      end
    end
  end

  return port
end

def get_instance_id(raw_instance_id)
  # /subscriptions/subscriptionid/resourceGroups/resource_group_name/providers/Microsoft.Compute/virtualMachines/computer_name
  instanceParts = raw_instance_id.split("/")
  #retrieve the last part
  instance_id = instanceParts.last

  return instance_id
end

def get_nic_name(raw_nic_id)
  # /subscriptions/subscription_id/resourceGroups/RG-VNET/providers/Microsoft.Network/networkInterfaces/nic_name
  nicnameParts = raw_nic_id.split("/")
  #retrieve the last part
  nic_name = nicnameParts.last

  return nic_name
end

# ==============================================================
#Variables
ci = {}
if node.workorder.has_key?("rfcCi")
  ci = node.workorder.rfcCi
else
  ci = node.workorder.ci
end

cloud_name = node.workorder.cloud.ciName

lb_service = nil
dns_service = nil
if !node.workorder.services["lb"].nil? && !node.workorder.services["dns"][cloud_name].nil?
  lb_service = node.workorder.services["lb"][cloud_name]
  dns_service = node.workorder.services["dns"][cloud_name]
end

if dns_service.nil? || lb_service.nil?
  Chef::Log.error("missing cloud service. services: #{node.workorder.services.inspect}")
  msg = "missing cloud service services"
  puts("***FAULT:FATAL=#{msg}")
  raise(msg)
end


location = lb_service[:ciAttributes][:location]
subscription_id = lb_service[:ciAttributes][:subscription]



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


asmb_name = assembly_name.gsub(/-/, "").downcase
plat_name = platform_name.gsub(/-/, "").downcase
env_name = environment_name.gsub(/-/, "").downcase
lb_name = "lb-#{plat_name}"


Chef::Log.info("Cloud Name: #{cloud_name}")
Chef::Log.info("Org: #{org_name}")
Chef::Log.info("Assembly: #{asmb_name}")
Chef::Log.info("Platform: #{platform_name}")
Chef::Log.info("Environment: #{env_name}")
Chef::Log.info("Security Group: #{security_group}")
Chef::Log.info("Resource Group: #{resource_group_name}")
Chef::Log.info("Load Balancer: #{lb_name}")

# ===== Create a LB =====
#   # LB Creation Steps
#
#   # 1 - Create Public IP (VIP)
#   # 2 - Create frontend IP address pool
#   # 3 - Create backend IP address pool
#   # 4 - Probes
#   # 5 - LB Rules
#   # 6 - Inbound NAT rules
#   # 7 - Create LB

credentials = get_credentials(lb_service)
public_ip_name = ''
public_ip = nil
subnet = nil
if xpress_route_enabled

  vnet_name = lb_service[:ciAttributes][:network]
  master_rg = lb_service[:ciAttributes][:resource_group]


  vnet = get_vnet(credentials, subscription_id, master_rg, vnet_name)

  if vnet.nil?
    msg = "Could not retrieve vnet '#{vnet_name}' from express route"
    Chef::Log.error(msg)
    puts "***FAULT:FATAL=#{msg}"
    raise msg
  end

  if vnet.properties.subnets.count < 1
    msg = "VNET '#{vnet_name}' does not have subnets"
    Chef::Log.error(msg)
    puts "***FAULT:FATAL=#{msg}"
    raise msg
  end

  #NOTE: for simplicity, we are going to grab the first subnet.
  subnet = vnet.properties.subnets[0]

else
  # Public IP Config
  nameutil = Utils::NameUtils.new()
  public_ip_name = nameutil.get_component_name("lb_publicip",node['workorder']['rfcCi']['ciId'])
  public_ip = create_update_public_ip(credentials, subscription_id, location, resource_group_name, public_ip_name)
end



# Frontend IP Config
frontend_ip_config_name = 'LB-FrontEndIP'
frontend_ip_config = create_frontend_ipconfig(subscription_id, resource_group_name, lb_name, frontend_ip_config_name, public_ip, subnet)
frontend_ip_configs = Array.new
frontend_ip_configs.push(frontend_ip_config)


# Backend Address Pool
backend_address_pool_name = 'LB-BackEndAddressPool'
backend_address_pool = create_backend_address_pool(subscription_id, resource_group_name, lb_name, backend_address_pool_name)
backend_address_pools = Array.new
backend_address_pools.push(backend_address_pool)


# ECV/Probes
probes = Array.new
ecvs = get_probes()

ecvs.each do |ecv|
  probe =  create_probe(subscription_id, resource_group_name, lb_name, ecv[:probe_name], ecv[:protocol], ecv[:port], ecv[:interval_secs], ecv[:num_probes], ecv[:request_path])
  Chef::Log.info("Probe => name:#{ecv[:probe_name]}; protocol:#{ecv[:protocol]}; port:#{ecv[:port]}; path:#{ecv[:request_path]}")
  probes.push(probe)
end


# Listeners/LB Rules
lb_rules = Array.new
listeners = get_listeners()

listeners.each do |listener|
  lbrule_name = "#{env_name}.#{platform_name}-#{listener.vport}_#{listener.iport}tcp-#{ci[:ciId]}-lbrule"
  Chef::Log.info("LBRule: #{lbrule_name}")
  lb_rule_name = lbrule_name #listener.name
  frontend_port = listener.vport
  backend_port = listener.iport
  protocol = Azure::ARM::Network::Models::TransportProtocol::Tcp
  load_distribution = Azure::ARM::Network::Models::LoadDistribution::Default
  lb_rule = create_lb_rule(lb_rule_name, load_distribution, protocol, frontend_port, backend_port, nil, frontend_ip_config, backend_address_pool)
  lb_rules.push(lb_rule)
end


compute_nodes = get_compute_nodes()

# Inbound NAT Rules
Chef::Log.info("Configuring NAT Rules ...")

compute_natrules = Array.new
nat_rules = Array.new

if compute_nodes.count > 0
  port_increment = 1000
  port_counter = 1
  front_port = 0

  compute_nodes.each do |compute_node|
    idle_min = 5
    nat_rule_name = "NatRule-#{compute_node[:ciId]}-#{compute_node[:allow_port]}tcp"
    front_port = (compute_node[:allow_port].to_i * port_increment) + port_counter
    frontend_port = front_port
    backend_port = compute_node[:allow_port].to_i
    protocol = Azure::ARM::Network::Models::TransportProtocol::Tcp

    Chef::Log.info("NAT Rule: #{nat_rule_name}")
    Chef::Log.info("NAT Rule Front port: #{frontend_port}")
    Chef::Log.info("NAT Rule Back port: #{backend_port}")

    nat_rule = create_inbound_nat_rule(subscription_id, resource_group_name, lb_name, nat_rule_name, idle_min, protocol, frontend_port , backend_port, frontend_ip_config, nil)

    nat_rules.push(nat_rule)

    compute_natrules.push({
                              :instance_id => compute_node[:instance_id],
                              :nat_rule => nat_rule
                          })
    port_counter += 1
  end

end


lb_props = create_lb_props(frontend_ip_configs, backend_address_pools, lb_rules, nat_rules, probes)


start_time = Time.now.to_i
lb = create_update_lb(credentials, subscription_id, location, resource_group_name, lb_name, lb_props)
end_time = Time.now.to_i
duration = end_time - start_time

if lb.nil?
  #Load Balancer was not created. Exit with error
  msg = "Load Balancer '#{lb.name}' could not be created"
  puts("***FAULT:FATAL=#{msg}")
  raise msg
else

  Chef::Log.info("Load Balancer '#{lb.name}' created/updated in #{duration} seconds")

  if compute_natrules.empty?
    Chef::Log.info('No computes to load balanced found!')
  else
    # Traverse the compute-natrules
    compute_natrules.each do |compute|
      instance_id = get_instance_id(compute[:instance_id])

      #Get the azure VM based on instance ID
      vm = get_vm(credentials, subscription_id, resource_group_name, instance_id)
      if vm.nil?
        next #could not find VM. Nothing to be done; skipping
      else
        #the asumption is that each VM will have only one NIC
        nic = vm.properties.network_profile.network_interfaces[0]
        nic_name = get_nic_name(nic.id)

        nic = get_nic(credentials, subscription_id, resource_group_name, nic_name)
        if nic.nil?
          next #Could not find NIC. Nothing to be done; skipping
        else
          nic.properties.ip_configurations[0].properties.load_balancer_backend_address_pools = backend_address_pools
          nic.properties.ip_configurations[0].properties.load_balancer_inbound_nat_rules = [compute[:nat_rule]]
          nic = create_update_nic(credentials, subscription_id, location, resource_group_name, nic_name, nic.properties)
        end
      end
    end #end of compute_natrules loop
  end  #end of compute_nodes IF
end #end of main lb IF


lbip = nil
if xpress_route_enabled
  lbip = lb.properties.frontend_ipconfigurations[0].properties.private_ipaddress
else
  public_ip = get_public_ip(credentials,subscription_id, resource_group_name, public_ip_name)
  if public_ip != nil
    lbip = public_ip.properties.ip_address
  end
end

if lbip.nil? || lbip == ''
  msg = "Load Balancer '#{lb.name}' NOT configured with IP"
  puts("***FAULT:FATAL=#{msg}")
  raise(msg)
else
  msg = "AzureLB IP: #{lbip}"
  Chef::Log.info(msg)
  node.set[:azurelb_ip] = lbip
end

