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
    resource_group_name = '<RG_NAME>'
    ag_name = '<AG_NAME>'

    @gateway = AzureNetwork::Gateway.new(resource_group_name, ag_name, credentials, subscription_id)
  end

  describe '#set_gateway_configuration' do
    it 'checks gateway configuration object name' do
      subnet = double
      gateway_configuration = @gateway.set_gateway_configuration(subnet)

      expect(gateway_configuration.name).to eq('ag-GatewayIP')
    end
  end

  describe '#set_backend_address_pool' do
    it 'checks backend pool object name' do
      backend_address_list = []
      backend_pool = @gateway.set_backend_address_pool(backend_address_list)

      expect(backend_pool.name).to eq('AG-BackEndAddressPool')
    end
  end

  describe '#set_https_settings' do
    it 'varify if cookies are enabled in https settings' do
      http_settings = @gateway.set_https_settings

      expect(http_settings.name).to eq('gateway_settings')
      expect(http_settings.properties.cookie_based_affinity).to eq(ApplicationGatewayCookieBasedAffinity::Enabled)
    end
    it 'varify if cookies are disabled in https settings' do
      http_settings = @gateway.set_https_settings(false)

      expect(http_settings.properties.cookie_based_affinity).to eq(ApplicationGatewayCookieBasedAffinity::Disabled)
    end
  end

  describe '#set_gateway_port' do
    it 'verify application gateway front port is 443 if ssl certificate exists' do
      gatewat_fronend_port = @gateway.set_gateway_port(true)

      expect(gatewat_fronend_port.name).to eq('gateway_front_port')
      expect(gatewat_fronend_port.properties.port).to eq(443)
    end
    it 'verify if application gateway front port is 80 if ssl certificate does not exist' do
      gatewat_fronend_port = @gateway.set_gateway_port(false)

      expect(gatewat_fronend_port.properties.port).to eq(80)
    end
  end

  describe '#set_frontend_ip_config' do
    it 'sets the subnet for frontend ip configurations if public IP is nil' do
      public_ip = nil
      subnet = double
      frontend_ip_config = @gateway.set_frontend_ip_config(public_ip, subnet)

      expect(frontend_ip_config.name).to eq('frontend_ip_config')
      expect(frontend_ip_config.properties.private_ipallocation_method).to eq(IpAllocationMethod::Dynamic)
      expect(frontend_ip_config.properties.subnet).to_not eq(nil)
    end
    it 'sets the public IP for frontend ip configurations if public IP is not nil' do
      public_ip = double
      subnet = nil
      frontend_ip_config = @gateway.set_frontend_ip_config(public_ip, subnet)

      expect(frontend_ip_config.properties.public_ipaddress).to_not eq(nil)
    end
  end

  describe '#set_ssl_certificate' do
    it 'checks attribute values of ssl certificate object' do
      data = 'DATA'
      password = 'PASSWORD'
      ssl_certificate = @gateway.set_ssl_certificate(data, password)

      expect(ssl_certificate.name).to eq('ssl_certificate')
      expect(ssl_certificate.properties.data).to eq(data)
      expect(ssl_certificate.properties.password).to eq(password)
    end
  end

  describe '#set_listener' do
    it 'returns application gateway listener properties with HTTPS protocol' do
      listener = @gateway.set_listener(true)

      expect(listener.name).to eq('gateway_listener')
      expect(listener.properties.protocol).to eq(ApplicationGatewayProtocol::Https)
    end
    it 'returns application gateway listener properties with HTTP protocol' do
      listener = @gateway.set_listener(false)

      expect(listener.name).to eq('gateway_listener')
      expect(listener.properties.protocol).to eq(ApplicationGatewayProtocol::Http)
    end
  end

  describe '#set_gateway_request_routing_rule' do
    it 'checks gateway request routing rule name' do
      routing_rule = @gateway.set_gateway_request_routing_rule

      expect(routing_rule.name).to eq('gateway_request_route_rule')
    end
  end

  describe '#set_gateway_sku' do
    it 'returns gateway sku object having sku name small' do
      sku_name = 'small'
      gateway_sku = @gateway.set_gateway_sku(sku_name)

      expect(gateway_sku.tier).to eq(ApplicationGatewayTier::Standard)
      expect(gateway_sku.capacity).to eq(2)
      expect(gateway_sku.name).to eq(ApplicationGatewaySkuName::StandardSmall)
    end
    it 'returns gateway sku object having sku name medium' do
      sku_name = 'medium'
      gateway_sku = @gateway.set_gateway_sku(sku_name)

      expect(gateway_sku.tier).to eq(ApplicationGatewayTier::Standard)
      expect(gateway_sku.capacity).to eq(2)
      expect(gateway_sku.name).to eq(ApplicationGatewaySkuName::StandardMedium)
    end
    it 'returns gateway sku object having sku name large' do
      sku_name = 'large'
      gateway_sku = @gateway.set_gateway_sku(sku_name)

      expect(gateway_sku.tier).to eq(ApplicationGatewayTier::Standard)
      expect(gateway_sku.capacity).to eq(2)
      expect(gateway_sku.name).to eq(ApplicationGatewaySkuName::StandardLarge)
    end
    it 'returns gateway sku object having sku name medium' do
      sku_name = 'ANY_OTHER'
      gateway_sku = @gateway.set_gateway_sku(sku_name)

      expect(gateway_sku.tier).to eq(ApplicationGatewayTier::Standard)
      expect(gateway_sku.capacity).to eq(2)
      expect(gateway_sku.name).to eq(ApplicationGatewaySkuName::StandardMedium)
    end
  end

  describe '#get_gateway' do
    it 'checks gateway_object attribute values' do
      location = 'EAST-US'
      ssl_certificate_exist = true

      gateway_object = @gateway.get_gateway(location, ssl_certificate_exist)
      expect(gateway_object.name).to eq('<AG_NAME>')
      expect(gateway_object.location).to eq(location)
    end
  end

  describe '#create_or_update' do
    it 'creates application gateway successfully' do
      gateway = double
      promise = double
      response = double

      allow(response).to receive(:body) { 'BODY' }
      allow(promise).to receive(:value!) { response }
      allow(@gateway.client.application_gateways).to receive(:create_or_update) { promise }
      create_gw = @gateway.create_or_update(gateway)
      expect(create_gw).to_not eq(nil)
    end
    it 'raises AzureOperationError exception while creating application gateway' do
      gateway = double

      allow(@gateway.client.application_gateways).to receive(:create_or_update) .and_raise(MsRestAzure::AzureOperationError.new('Errors'))
      expect { @gateway.create_or_update(gateway) }.to raise_error('FATAL ERROR creating Gateway....')
    end
    it 'raises exception while creating application gateway' do
      gateway = double

      allow(@gateway.client.application_gateways).to receive(:create_or_update) .and_raise(MsRest::HttpOperationError.new('Error'))
      expect { @gateway.create_or_update(gateway) }.to raise_error('Gateway creation error....')
    end
  end

  describe '#delete' do
    it 'deletes application gateway successfully' do
      promise = double
      response = double

      allow(response).to receive(:body) { 'BODY' }
      allow(promise).to receive(:value!) { response }
      allow(@gateway.client.application_gateways).to receive(:delete) { promise }
      delete_gw = @gateway.delete
      expect(delete_gw).to_not eq(nil)
    end
    it 'raises AzureOperationError exception' do
      allow(@gateway.client.application_gateways).to receive(:delete) .and_raise(MsRestAzure::AzureOperationError.new('Errors'))
      expect { @gateway.delete }.to raise_error('FATAL ERROR deleting Gateway....')
    end
    it 'raises exception while deleting application gateway' do
      allow(@gateway.client.application_gateways).to receive(:delete) .and_raise(MsRest::HttpOperationError.new('Error'))
      expect { @gateway.delete }.to raise_error('Gateway deleting error....')
    end
  end
end
