# **Rubocop Suppression**
# rubocop:disable LineLength
require 'azure_mgmt_network'
require 'chef'

module AzureNetwork
  # Cookbook Name:: Azure_gateway
  class Gateway
    include Azure::ARM::Network
    include Azure::ARM::Network::Models

    attr_accessor :client

    def initialize(credentials, subscription_id)
      @subscription_id = subscription_id
      @client = Azure::ARM::Network::NetworkResourceProviderClient.new(credentials)
      @client.subscription_id = @subscription_id
    end

    def self.configure_gateway_configuration(gateway_config_name, subnet)
      gateway_ipconfig = Azure::ARM::Network::Models::ApplicationGatewayIpConfiguration.new
      gateway_ipconfig.name = gateway_config_name
      properties = Azure::ARM::Network::Models::ApplicationGatewayIpConfigurationPropertiesFormat.new
      properties.subnet = subnet
      gateway_ipconfig.properties = properties

      gateway_ipconfig
    end

    def self.configure_backend_address_pool(resource_group_name, subscription_id, ag_name, backend_address_pool_name, backend_address_list)
      gateway_backend_pool = ApplicationGatewayBackendAddressPool.new
      backpool_prop = ApplicationGatewayBackendAddressPoolPropertiesFormat.new
      backend_addresses = []
      backend_address_list.each do |backend_address|
        backend_address_obj = ApplicationGatewayBackendAddress.new
        backend_address_obj.ip_address = backend_address
        backend_addresses.push(backend_address_obj)
      end

      backpool_prop.backend_addresses = backend_addresses

      gateway_backend_pool.name = backend_address_pool_name
      gateway_backend_pool.id = "/subscriptions/#{subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.Network/applicationGateways/#{ag_name}/backendAddressPools/#{backend_address_pool_name}"
      gateway_backend_pool.properties = backpool_prop
      gateway_backend_pool
    end

    def self.configure_https_settings(resource_group_name, subscription_id, ag_name, http_settings_name, enable_cookie = true)
      gateway_backend_http_settings_prop = ApplicationGatewayBackendHttpSettingsPropertiesFormat.new
      gateway_backend_http_settings_prop.port = 80
      gateway_backend_http_settings_prop.protocol = ApplicationGatewayProtocol::Http
      if enable_cookie
        gateway_backend_http_settings_prop.cookie_based_affinity = ApplicationGatewayCookieBasedAffinity::Enabled
      else
        gateway_backend_http_settings_prop.cookie_based_affinity = ApplicationGatewayCookieBasedAffinity::Disabled
      end

      gateway_backend_http_settings = ApplicationGatewayBackendHttpSettings.new
      gateway_backend_http_settings.name = http_settings_name
      gateway_backend_http_settings.id = "/subscriptions/#{subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.Network/applicationGateways/#{ag_name}/backendHttpSettingsCollection/#{http_settings_name}"
      gateway_backend_http_settings.properties = gateway_backend_http_settings_prop
      gateway_backend_http_settings
    end

    def self.configure_gateway_port(resource_group_name, subscription_id, ag_name, gateway_front_port_name, ssl_certificate_exist = true)
      gateway_front_port_prop = ApplicationGatewayFrontendPortPropertiesFormat.new
      gateway_front_port_prop.port = ssl_certificate_exist ? 443 : 80
      gateway_front_port = ApplicationGatewayFrontendPort.new
      gateway_front_port.name = gateway_front_port_name
      gateway_front_port.id = "/subscriptions/#{subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.Network/applicationGateways/#{ag_name}/frontendPorts/#{gateway_front_port_name}"
      gateway_front_port.properties = gateway_front_port_prop
      gateway_front_port
    end

    def self.configure_frontend_ip_config(resource_group_name, subscription_id, ag_name, frontend_ip_config_name, public_ip, subnet)
      frontend_ip_config_prop = ApplicationGatewayFrontendIpConfigurationPropertiesFormat.new
      if public_ip.nil?
        frontend_ip_config_prop.subnet = subnet
        frontend_ip_config_prop.private_ipallocation_method = IpAllocationMethod::Dynamic
      else
        frontend_ip_config_prop.public_ipaddress = public_ip
      end
      frontend_ip_config = ApplicationGatewayFrontendIpConfiguration.new
      frontend_ip_config.name = frontend_ip_config_name
      frontend_ip_config.id = "/subscriptions/#{subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.Network/applicationGateways/#{ag_name}/frontendIPConfigurations/#{frontend_ip_config_name}"
      frontend_ip_config.properties = frontend_ip_config_prop
      frontend_ip_config
    end

    def self.configure_ssl_certificate(resource_group_name, subscription_id, ag_name, ssl_certificate_name, data, password)
      ssl_certificate_prop = ApplicationGatewaySslCertificatePropertiesFormat.new
      ssl_certificate_prop.data = data
      ssl_certificate_prop.password = password
      ssl_certificate = ApplicationGatewaySslCertificate.new
      ssl_certificate.name = ssl_certificate_name
      ssl_certificate.id = "/subscriptions/#{subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.Network/applicationGateways/#{ag_name}/sslCertificates/#{ssl_certificate_name}"
      ssl_certificate.properties = ssl_certificate_prop
      ssl_certificate
    end

    def self.configure_listener(resource_group_name, subscription_id, ag_name, gateway_listener_name, frontend_ip_config, gateway_front_port, ssl_certificate, ssl_certificate_exist)
      gateway_listener_prop = ApplicationGatewayHttpListenerPropertiesFormat.new
      gateway_listener_prop.protocol = ssl_certificate_exist ? ApplicationGatewayProtocol::Https : ApplicationGatewayProtocol::Http
      gateway_listener_prop.frontend_ip_configuration = frontend_ip_config
      gateway_listener_prop.frontend_port = gateway_front_port
      gateway_listener_prop.ssl_certificate = ssl_certificate

      gateway_listener = ApplicationGatewayHttpListener.new
      gateway_listener.name = gateway_listener_name
      gateway_listener.id = "/subscriptions/#{subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.Network/applicationGateways/#{ag_name}/httpListeners/#{gateway_listener_name}"
      gateway_listener.properties = gateway_listener_prop
      gateway_listener
    end

    def self.configure_gateway_request_routing_rule(gateway_request_route_rule_name, gateway_listener, backend_address_pool, gateway_backend_http_settings)
      gateway_request_route_rule_prop = ApplicationGatewayRequestRoutingRulePropertiesFormat.new
      gateway_request_route_rule_prop.rule_type = ApplicationGatewayRequestRoutingRuleType::Basic
      gateway_request_route_rule_prop.backend_http_settings = gateway_backend_http_settings
      gateway_request_route_rule_prop.http_listener = gateway_listener
      gateway_request_route_rule_prop.backend_address_pool = backend_address_pool

      gateway_request_route_rule = ApplicationGatewayRequestRoutingRule.new
      gateway_request_route_rule.name = gateway_request_route_rule_name
      gateway_request_route_rule.properties = gateway_request_route_rule_prop
      gateway_request_route_rule
    end

    def self.configure_gateway_sku(sku_name)
      gateway_sku = ApplicationGatewaySku.new
      case sku_name.downcase
      when 'small'
        gateway_sku.name = ApplicationGatewaySkuName::StandardSmall
      when 'medium'
        gateway_sku.name = ApplicationGatewaySkuName::StandardMedium
      when 'large'
        gateway_sku.name = ApplicationGatewaySkuName::StandardLarge
      else
        gateway_sku.name = ApplicationGatewaySkuName::StandardMedium
      end

      gateway_sku.tier = ApplicationGatewayTier::Standard
      gateway_sku.capacity = 2
      gateway_sku
    end

    def self.configure_gateway(ag_name, location, backend_address_pools, gateway_ipconfigs, gateway_front_ports, gateway_listeners, frontend_ip_configs, gateway_backend_http_settings, gateway_sku, gateway_request_route_rules, ssl_certificate_exist, ssl_certificates)
      gateway_prop = ApplicationGatewayPropertiesFormat.new
      gateway_prop.backend_address_pools = backend_address_pools
      gateway_prop.backend_http_settings_collection = gateway_backend_http_settings
      gateway_prop.frontend_ip_configurations = frontend_ip_configs
      gateway_prop.gateway_ip_configurations = gateway_ipconfigs
      gateway_prop.frontend_ports = gateway_front_ports
      gateway_prop.http_listeners = gateway_listeners
      gateway_prop.request_routing_rules = gateway_request_route_rules
      gateway_prop.sku = gateway_sku
      if ssl_certificate_exist
        gateway_prop.ssl_certificates = ssl_certificates
      end
      gateway = ApplicationGateway.new
      gateway.name = ag_name
      gateway.location = location
      gateway.properties = gateway_prop
      gateway
    end

    def create_update(resource_group_name, ag_name, gateway)
      begin
        promise = @client.application_gateways.create_or_update(resource_group_name, ag_name, gateway)

        response = promise.value!
        gateway_result = response.body
        gateway_result
      rescue MsRestAzure::AzureOperationError => e
        msg = 'FATAL ERROR creating Gateway....'
        Chef::Log.error("FATAL ERROR creating Gateway....: #{e.body}")
        raise msg
      rescue => e
        msg = 'Gateway creation error....'
        Chef::Log.error("Gateway creation error....: #{e.message}")
        raise msg
      end
    end

    def delete(resource_group_name, ag_name)
      begin
        promise = @client.application_gateways.delete(resource_group_name, ag_name)
        response = promise.value!
        gateway_result = response.body
      rescue MsRestAzure::AzureOperationError => e
        msg = 'FATAL ERROR deleting Gateway....'
        Chef::Log.error("FATAL ERROR deleting Gateway....: #{e.body}")
        raise msg
      rescue => e
        msg = 'Gateway deleting error....'
        Chef::Log.error("Gateway deleting error....: #{e.body}")
        raise msg
      end
      gateway_result
    end
  end
end
