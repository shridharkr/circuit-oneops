# **Rubocop Suppression**
# rubocop:disable LineLength
require 'simplecov'
SimpleCov.start
require File.expand_path('../../libraries/application_gateway.rb', __FILE__)
require 'azure_mgmt_network'

include Azure::ARM::Network
include Azure::ARM::Network::Models

describe AzureNetwork::Gateway do
  before do
    token_provider = MsRestAzure::ApplicationTokenProvider.new('tenant_id', 'client_id', 'client_secret')
    credentials = MsRest::TokenCredentials.new(token_provider)
    subscription_id = '<SUBSCRIPTION_ID>'

    @gateway = AzureNetwork::Gateway.new(credentials, subscription_id)
  end

  describe '#configure_gateway_configuration' do
    it 'checks gateway configuration object name' do
      subnet = double
      gateway_configuration = AzureNetwork::Gateway.configure_gateway_configuration('GatewayConfigName', subnet)

      expect(gateway_configuration.name).to eq('GatewayConfigName')
    end
  end

  describe '#configure_backend_address_pool' do
    it 'checks backend pool object name' do
      backend_address_pool_name = 'POOL_NAME'
      backend_address_list = []
      backend_pool = AzureNetwork::Gateway.configure_backend_address_pool('resource_group_name', 'subscription_id', 'ag_name', backend_address_pool_name, backend_address_list)

      expect(backend_pool.name).to eq(backend_address_pool_name)
    end
  end

  describe '#configure_https_settings' do
    it 'varify if cookies are enabled in https settings' do
      http_settings_name = 'HTTP_SETTINGS'
      http_settings = AzureNetwork::Gateway.configure_https_settings('resource_group_name', 'subscription_id', 'ag_name', http_settings_name)

      expect(http_settings.name).to eq(http_settings_name)
      expect(http_settings.properties.cookie_based_affinity).to eq(ApplicationGatewayCookieBasedAffinity::Enabled)
    end
    it 'varify if cookies are disabled in https settings' do
      http_settings_name = 'HTTP_SETTINGS'
      http_settings = AzureNetwork::Gateway.configure_https_settings('resource_group_name', 'subscription_id', 'ag_name', http_settings_name, false)

      expect(http_settings.properties.cookie_based_affinity).to eq(ApplicationGatewayCookieBasedAffinity::Disabled)
    end
  end

  describe '#configure_gateway_port' do
    it 'verify application gateway front port is 443 if ssl certificate exists' do
      gateway_front_port_name = 'FRONTEND_PORT_NAME'
      gatewat_fronend_port = AzureNetwork::Gateway.configure_gateway_port('resource_group_name', 'subscription_id', 'ag_name', gateway_front_port_name)

      expect(gatewat_fronend_port.name).to eq(gateway_front_port_name)
      expect(gatewat_fronend_port.properties.port).to eq(443)
    end
    it 'verify if application gateway front port is 80 if ssl certificate does not exist' do
      gateway_front_port_name = 'FRONTEND_PORT_NAME'
      gatewat_fronend_port = AzureNetwork::Gateway.configure_gateway_port('resource_group_name', 'subscription_id', 'ag_name', gateway_front_port_name, false)

      expect(gatewat_fronend_port.properties.port).to eq(80)
    end
  end

  describe '#configure_frontend_ip_config' do
    it 'sets the subnet for frontend ip configurations if public IP is nil' do
      frontend_ip_config_name = 'FE_IP_CONFIG_NAME'
      public_ip = nil
      subnet = double
      frontend_ip_config = AzureNetwork::Gateway.configure_frontend_ip_config('resource_group_name', 'subscription_id', 'ag_name', frontend_ip_config_name, public_ip, subnet)

      expect(frontend_ip_config.name).to eq(frontend_ip_config_name)
      expect(frontend_ip_config.properties.private_ipallocation_method).to eq(IpAllocationMethod::Dynamic)
      expect(frontend_ip_config.properties.subnet).to_not eq(nil)
    end
    it 'sets the public IP for frontend ip configurations if public IP is not nil' do
      frontend_ip_config_name = 'FE_IP_CONFIG_NAME'
      public_ip = double
      subnet = nil
      frontend_ip_config = AzureNetwork::Gateway.configure_frontend_ip_config('resource_group_name', 'subscription_id', 'ag_name', frontend_ip_config_name, public_ip, subnet)

      expect(frontend_ip_config.properties.public_ipaddress).to_not eq(nil)
    end
  end

  describe '#configure_ssl_certificate' do
    it 'checks attribute values of ssl certificate object' do
      ssl_certificate_name = 'CERTIFICATE_NAME'
      data = 'DATA'
      password = 'PASSWORD'
      ssl_certificate = AzureNetwork::Gateway.configure_ssl_certificate('resource_group_name', 'subscription_id', 'ag_name', ssl_certificate_name, data, password)

      expect(ssl_certificate.name).to eq(ssl_certificate_name)
      expect(ssl_certificate.properties.data).to eq(data)
      expect(ssl_certificate.properties.password).to eq(password)
    end
  end

  describe '#configure_listener' do
    gateway_listener_name = 'LISTENER_NAME'
    frontend_ip_config = 'PE_IP_CONFIG'
    gateway_front_port = 'FE_PORT'
    ssl_certificate = 'CERTIFICATE_DATA'

    it 'returns application gateway listener properties with HTTPS protocol' do
      listener = AzureNetwork::Gateway.configure_listener('resource_group_name', 'subscription_id', 'ag_name', gateway_listener_name, frontend_ip_config, gateway_front_port, ssl_certificate, true)

      expect(listener.name).to eq(gateway_listener_name)
      expect(listener.properties.frontend_ip_configuration).to eq(frontend_ip_config)
      expect(listener.properties.frontend_port).to eq(gateway_front_port)
      expect(listener.properties.ssl_certificate).to eq(ssl_certificate)
      expect(listener.properties.protocol).to eq(ApplicationGatewayProtocol::Https)
    end
    it 'returns application gateway listener properties with HTTP protocol' do
      listener = AzureNetwork::Gateway.configure_listener('resource_group_name', 'subscription_id', 'ag_name', gateway_listener_name, frontend_ip_config, gateway_front_port, ssl_certificate, false)

      expect(listener.name).to eq(gateway_listener_name)
      expect(listener.properties.frontend_ip_configuration).to eq(frontend_ip_config)
      expect(listener.properties.frontend_port).to eq(gateway_front_port)
      expect(listener.properties.ssl_certificate).to eq(ssl_certificate)
      expect(listener.properties.protocol).to eq(ApplicationGatewayProtocol::Http)
    end
  end

  describe '#configure_gateway_request_routing_rule' do
    it 'checks gateway request routing rule name' do
      routing_rule_name = 'ROUTE_RULE_NAME'
      gateway_listener = double
      backend_address_pool = double
      gateway_settings = double
      routing_rule = AzureNetwork::Gateway.configure_gateway_request_routing_rule(routing_rule_name, gateway_listener, backend_address_pool, gateway_settings)

      expect(routing_rule.name).to eq(routing_rule_name)
    end
  end

  describe '#configure_gateway_sku' do
    it 'returns gateway sku object having sku name small' do
      sku_name = 'small'
      gateway_sku = AzureNetwork::Gateway.configure_gateway_sku(sku_name)

      expect(gateway_sku.tier).to eq(ApplicationGatewayTier::Standard)
      expect(gateway_sku.capacity).to eq(2)
      expect(gateway_sku.name).to eq(ApplicationGatewaySkuName::StandardSmall)
    end
    it 'returns gateway sku object having sku name medium' do
      sku_name = 'medium'
      gateway_sku = AzureNetwork::Gateway.configure_gateway_sku(sku_name)

      expect(gateway_sku.tier).to eq(ApplicationGatewayTier::Standard)
      expect(gateway_sku.capacity).to eq(2)
      expect(gateway_sku.name).to eq(ApplicationGatewaySkuName::StandardMedium)
    end
    it 'returns gateway sku object having sku name large' do
      sku_name = 'large'
      gateway_sku = AzureNetwork::Gateway.configure_gateway_sku(sku_name)

      expect(gateway_sku.tier).to eq(ApplicationGatewayTier::Standard)
      expect(gateway_sku.capacity).to eq(2)
      expect(gateway_sku.name).to eq(ApplicationGatewaySkuName::StandardLarge)
    end
    it 'returns gateway sku object having sku name medium' do
      sku_name = 'ANY_OTHER'
      gateway_sku = AzureNetwork::Gateway.configure_gateway_sku(sku_name)

      expect(gateway_sku.tier).to eq(ApplicationGatewayTier::Standard)
      expect(gateway_sku.capacity).to eq(2)
      expect(gateway_sku.name).to eq(ApplicationGatewaySkuName::StandardMedium)
    end
  end

  describe '#configure_gateway' do
    it 'checks gateway_object attribute values' do
      ag_name = 'AG_NAME'
      location = 'EAST-US'
      backend_address_pools = double
      appg_ipconfigs = double
      gateway_front_ports = double
      gateway_listeners = double
      frontend_ip_configs = double
      gateway_settings = double
      gateway_sku = double
      gateway_request_route_rules = double
      ssl_certificate_exist = double
      ssl_certificates = double

      gateway_object = AzureNetwork::Gateway.configure_gateway(ag_name, location, backend_address_pools, appg_ipconfigs, gateway_front_ports, gateway_listeners, frontend_ip_configs, gateway_settings, gateway_sku, gateway_request_route_rules, ssl_certificate_exist, ssl_certificates)
      expect(gateway_object.name).to eq(ag_name)
      expect(gateway_object.location).to eq(location)
    end
  end

  describe '#create_update_gateway' do
    it 'creates application gateway successfully' do
      resource_group_name = 'RG_DUMMY'
      ag_name = 'AG_DUMMY'
      gateway = double
      promise = double
      response = double

      allow(response).to receive(:body) { 'BODY' }
      allow(promise).to receive(:value!) { response }
      allow(@gateway.client.application_gateways).to receive(:create_or_update) { promise }
      create_gw = @gateway.create_update(resource_group_name, ag_name, gateway)
      expect(create_gw).to_not eq(nil)
    end
    it 'raises AzureOperationError exception while creating application gateway' do
      resource_group_name = 'RG_DUMMY'
      ag_name = 'AG_DUMMY'
      gateway = double

      allow(@gateway.client.application_gateways).to receive(:create_or_update) .and_raise(MsRestAzure::AzureOperationError.new('Errors'))
      expect { @gateway.create_update(resource_group_name, ag_name, gateway) }.to raise_error('FATAL ERROR creating Gateway....')
    end
    it 'raises exception while creating application gateway' do
      resource_group_name = 'RG_DUMMY'
      ag_name = 'AG_DUMMY'
      gateway = double

      allow(@gateway.client.application_gateways).to receive(:create_or_update) .and_raise(MsRest::HttpOperationError.new('Error'))
      expect { @gateway.create_update(resource_group_name, ag_name, gateway) }.to raise_error('Gateway creation error....')
    end
  end

  describe '#delete_gateway' do
    it 'deletes application gateway successfully' do
      resource_group_name = 'RG_DUMMY'
      ag_name = 'AG_DUMMY'
      promise = double
      response = double

      allow(response).to receive(:body) { 'BODY' }
      allow(promise).to receive(:value!) { response }
      allow(@gateway.client.application_gateways).to receive(:delete) { promise }
      delete_gw = @gateway.delete(resource_group_name, ag_name)
      expect(delete_gw).to_not eq(nil)
    end
    it 'raises AzureOperationError exception' do
      resource_group_name = 'RG_DUMMY'
      ag_name = 'AG_DUMMY'

      allow(@gateway.client.application_gateways).to receive(:delete) .and_raise(MsRestAzure::AzureOperationError.new('Errors'))
      expect { @gateway.delete(resource_group_name, ag_name) }.to raise_error('FATAL ERROR deleting Gateway....')
    end
    it 'raises exception while deleting application gateway' do
      resource_group_name = 'RG_DUMMY'
      ag_name = 'AG_DUMMY'

      allow(@gateway.client.application_gateways).to receive(:delete) .and_raise(MsRest::HttpOperationError.new('Error'))
      expect { @gateway.delete(resource_group_name, ag_name) }.to raise_error('Gateway deleting error....')
    end
  end
end
