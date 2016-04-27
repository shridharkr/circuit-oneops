
require 'azure_mgmt_compute'
require 'azure_mgmt_network'


#set the proxy if it exists as a cloud var
AzureCommon::AzureUtils.set_proxy(node.workorder.payLoad.OO_CLOUD_VARS)

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'

# ==============================================================

def create_publicip(credentials, subscription_id, location, resource_group_name, public_ip_name)
  pip_props = Azure::ARM::Network::Models::PublicIpAddressPropertiesFormat.new
  pip_props.idle_timeout_in_minutes = 5
  pip_props.public_ipallocation_method = Azure::ARM::Network::Models::IpAllocationMethod::Dynamic

  public_ip_address = Azure::ARM::Network::Models::PublicIpAddress.new
  public_ip_address.location = location
  public_ip_address.properties = pip_props

  pip_svc = AzureNetwork::PublicIp.new(credentials, subscription_id)
  pip = pip_svc.create_update(resource_group_name, public_ip_name, public_ip_address)
  return pip
end

def get_probes_from_wo
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

def get_probes(subscription_id, resource_group_name, lb_name)
  probes = Array.new
  ecvs = get_probes_from_wo()

  ecvs.each do |ecv|
    probe =  AzureNetwork::LoadBalancer.create_probe(subscription_id, resource_group_name, lb_name, ecv[:probe_name], ecv[:protocol], ecv[:port], ecv[:interval_secs], ecv[:num_probes], ecv[:request_path])
    OOLog.info("Probe name: #{ecv[:probe_name]}")
    OOLog.info("Probe protocol: #{ecv[:protocol]}")
    OOLog.info("Probe port: #{ecv[:port]}")
    OOLog.info("Probe path: #{ecv[:request_path]}")
    probes.push(probe)
  end

  return probes
end

def get_listeners_from_wo
  listeners = Array.new

  if node["loadbalancers"]
    raw_data = node['loadbalancers']
    raw_data.each do |listener|
      listeners.push(listener)
    end
  end

  return listeners
end

def get_loadbalancer_rules(env_name, platform_name, probes, frontend_ipconfig, backend_address_pool)
  lb_rules = Array.new

  ci = {}
  if node.workorder.has_key?("rfcCi")
    ci = node.workorder.rfcCi
  else
    ci = node.workorder.ci
  end

  listeners = get_listeners_from_wo()

  listeners.each do |listener|
    lb_rule_name = "#{env_name}.#{platform_name}-#{listener.vport}_#{listener.iport}tcp-#{ci[:ciId]}-lbrule"
    frontend_port = listener.vport
    backend_port = listener.iport
    protocol = Azure::ARM::Network::Models::TransportProtocol::Tcp
    load_distribution = Azure::ARM::Network::Models::LoadDistribution::Default

    probe = nil
    if probes.length > 0
      probe = probes[0]
    end

    lb_rule = AzureNetwork::LoadBalancer.create_lb_rule(lb_rule_name, load_distribution, protocol, frontend_port, backend_port, probe, frontend_ipconfig, backend_address_pool)
    OOLog.info("LB Rule: #{lb_rule_name}")
    OOLog.info("LB Rule Frontend port: #{frontend_port}")
    OOLog.info("LB Rule Backend port: #{backend_port}")
    OOLog.info("LB Rule Protocol: #{protocol}")
    # OOLog.info("LB Rule Probe: #{lb_rule.}")
    OOLog.info("LB Rule Load Distribution: #{load_distribution}")
    lb_rules.push(lb_rule)
  end

  return lb_rules
end

def get_compute_nodes_from_wo
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

# This method constructs two arrays.
# NAT Rule array
# Compute NAT Rule.
# The second array is used to easily get the compute info along with its associated NAT rule
def get_compute_nat_rules(subscription_id, resource_group_name, lb_name, frontend_ipconfig, nat_rules, compute_natrules)

  compute_nodes = get_compute_nodes_from_wo()
  if compute_nodes.count > 0
    port_increment = 1000
    port_counter = 1
    front_port = 0
    OOLog.info("Configuring NAT Rules ...")
    compute_nodes.each do |compute_node|
      idle_min = 5
      nat_rule_name = "NatRule-#{compute_node[:ciId]}-#{compute_node[:allow_port]}tcp"
      front_port = (compute_node[:allow_port].to_i * port_increment) + port_counter
      frontend_port = front_port
      backend_port = compute_node[:allow_port].to_i
      protocol = Azure::ARM::Network::Models::TransportProtocol::Tcp

      OOLog.info("NAT Rule Name: #{nat_rule_name}")
      OOLog.info("NAT Rule Front port: #{frontend_port}")
      OOLog.info("NAT Rule Back port: #{backend_port}")

      nat_rule = AzureNetwork::LoadBalancer.create_inbound_nat_rule(subscription_id, resource_group_name, lb_name, nat_rule_name, idle_min, protocol, frontend_port , backend_port, frontend_ipconfig, nil)

      nat_rules.push(nat_rule)

      compute_natrules.push({
                                :instance_id => compute_node[:instance_id],
                                :instance_name => compute_node[:instance_name],
                                :nat_rule => nat_rule
                            })
      port_counter += 1
    end

    OOLog.info("Total NAT rules: #{nat_rules.count}")

  end

  return nat_rules
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

def get_nic_name(raw_nic_id)
  # /subscriptions/subscription_id/resourceGroups/vnet_name/providers/Microsoft.Network/networkInterfaces/nic_name
  nicnameParts = raw_nic_id.split("/")
  #retrieve the last part
  nic_name = nicnameParts.last

  return nic_name
end

# ==============================================================
#Variables

cloud_name = node.workorder.cloud.ciName

lb_service = nil
if !node.workorder.services["lb"].nil?
  lb_service = node.workorder.services["lb"][cloud_name]
end

if lb_service.nil?
  OOLog.fatal("Missing lb service! Cannot continue.")
end

location = lb_service[:ciAttributes][:location]
tenant_id = lb_service[:ciAttributes][:tenant_id]
client_id = lb_service[:ciAttributes][:client_id]
client_secret = lb_service[:ciAttributes][:client_secret]
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
resource_group_name = node['platform-resource-group']


plat_name = platform_name.gsub(/-/, "").downcase
env_name = environment_name.gsub(/-/, "").downcase
lb_name = "lb-#{plat_name}"

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

credentials = AzureCommon::AzureUtils.get_credentials(tenant_id, client_id, client_secret)
public_ip_name = ''
public_ip = nil
subnet = nil
# Public IP
if xpress_route_enabled

  vnet_name = lb_service[:ciAttributes][:network]
  master_rg = lb_service[:ciAttributes][:resource_group]

  vnet_svc = AzureNetwork::VirtualNetwork.new(credentials, subscription_id)
  vnet = vnet_svc.get_vnet(master_rg, vnet_name)

  if vnet.nil?
    OOLog.fatal("Could not retrieve vnet '#{vnet_name}' from express route")
  end

  if vnet.properties.subnets.count < 1
    OOLog.fatal("VNET '#{vnet_name}' does not have subnets")
  end

  #NOTE: for simplicity, we are going to grab the first subnet. This might change
  subnet = vnet.properties.subnets[0]

else
  # Public IP Config
  nameutil = Utils::NameUtils.new()
  public_ip_name = nameutil.get_component_name("lb_publicip",node['workorder']['rfcCi']['ciId'])
  public_ip = create_publicip(credentials, subscription_id, location, resource_group_name, public_ip_name)

  OOLog.info("PublicIP created. PIP: #{public_ip.name}")

end


# Frontend IP Config
frontend_ipconfig_name = 'LB-FrontEndIP'
frontend_ipconfig = AzureNetwork::LoadBalancer.create_frontend_ipconfig(subscription_id, resource_group_name, lb_name, frontend_ipconfig_name, public_ip, subnet)

frontend_ipconfigs = Array.new
frontend_ipconfigs.push(frontend_ipconfig)


# Backend Address Pool
backend_address_pool_name = 'LB-BackEndAddressPool'
backend_address_pool = AzureNetwork::LoadBalancer.create_backend_address_pool(subscription_id, resource_group_name, lb_name, backend_address_pool_name)

backend_address_pools = Array.new
backend_address_pools.push(backend_address_pool)


# ECV/Probes
probes = get_probes(subscription_id, resource_group_name, lb_name)

# Listeners/LB Rules
lb_rules = get_loadbalancer_rules(env_name, platform_name, probes, frontend_ipconfig, backend_address_pool)

# Inbound NAT Rules
compute_natrules = Array.new
nat_rules = Array.new
get_compute_nat_rules(subscription_id, resource_group_name, lb_name, frontend_ipconfig, nat_rules, compute_natrules)


# Configure LB properties
lb_props = AzureNetwork::LoadBalancer.create_lb_props(frontend_ipconfigs, backend_address_pools, lb_rules, nat_rules, probes)

# Create LB
lb_svc = AzureNetwork::LoadBalancer.new(credentials, subscription_id)
lb = lb_svc.create_update(location, resource_group_name, lb_name, lb_props)

if lb.nil?
  OOLog.fatal("Load Balancer '#{lb.name}' could not be created")
else

  if compute_natrules.empty?
    OOLog.info('No computes found for load balanced')
  else

    vm_svc = AzureCompute::VirtualMachine.new(credentials, subscription_id)
    nic_svc = AzureNetwork::NetworkInterfaceCard.new(credentials, subscription_id)
    nic_svc.rg_name = resource_group_name

    # Traverse the compute-natrules
    compute_natrules.each do |compute|
      #Get the azure VM
      vm = vm_svc.get(resource_group_name, compute[:instance_name])

      if vm.nil?
        OOLog.info("VM Not Fetched: '#{compute[:instance_name]}' ")
        next #could not find VM. Nothing to be done; skipping
      else
        #the asumption is that each VM will have only one NIC
        nic = vm.properties.network_profile.network_interfaces[0]
        nic_name = get_nic_name(nic.id)
        # nic = nic_svc.get(resource_group_name, nic_name)
        nic = nic_svc.get(nic_name)

        if nic.nil?
          next #Could not find NIC. Nothing to be done; skipping
        else
          #Update the NIC with LB info - Associate VM with LB
          nic.properties.ip_configurations[0].properties.load_balancer_backend_address_pools = backend_address_pools
          nic.properties.ip_configurations[0].properties.load_balancer_inbound_nat_rules = [compute[:nat_rule]]
          nic = nic_svc.create_update(location, resource_group_name, nic_name, nic.properties)
        end
      end
    end #end of compute_natrules loop
  end  #end of compute_nodes IF
end #end of main lb IF


lbip = nil
if xpress_route_enabled
  lbip = lb.properties.frontend_ipconfigurations[0].properties.private_ipaddress
else
  pip_svc = AzureNetwork::PublicIp.new(credentials, subscription_id)
  public_ip = pip_svc.get(resource_group_name, public_ip_name)
  if public_ip != nil
    lbip = public_ip.properties.ip_address
  end
end

if lbip.nil? || lbip == ''
  OOLog.fatal("Load Balancer '#{lb.name}' NOT configured with IP")
else
  OOLog.info("AzureLB IP: #{lbip}")
  node.set[:azurelb_ip] = lbip
end

