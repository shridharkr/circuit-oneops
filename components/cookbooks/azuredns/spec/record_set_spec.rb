# rubocop:disable LineLength
require File.expand_path('../../libraries/record_set.rb', __FILE__)
require 'json'
require 'rest-client'

describe AzureDns::RecordSet do
  before do
    platform_resource_group = 'azure_resource_group'
    token = '<DUMMY_TOKEN>'
    dns_attributes = {
      'tenant_id' => '<TENANT_ID>',
      'client_id' => '<CLIENT_ID>',
      'client_secret' => '<CLIENT_SECRET>',
      'subscription' => '<SUBSCRIPTION_ID>',
      'zone' => '<COM>' }
    JSON = double
    @record_sets = AzureDns::RecordSet.new(dns_attributes,
                                           token, platform_resource_group)
  end
  describe '#get_existing_records_for_recordset' do
    it 'returns records for recordset' do
      dns_response =
        {
          'id' => '<SUBSCRIPTION_ID>',
          'location' => 'global',
          'name' => 'www',
          'tags' => {},
          'type' => 'Microsoft.Network/dnszones/A',
          'etag' => '5b83020b-b59c-44be-8f19-a052ebe80fe7',
          'properties' =>
          {
            'TTL' => 3600,
            'ARecords' => [
              {
                'ipv4Address' => '4.3.2.1'
              },
              {
                'ipv4Address' => '5.3.2.1'
              }
            ]
          }
        }
      allow(RestClient).to receive(:get) {}
      allow(JSON).to receive(:parse) { dns_response }
      @record_sets.get_existing_records_for_recordset('A', 'Recordset_Name')
                  .length.should eq(2)
    end
  end

  describe '#get_existing_records_for_recordset' do
    it 'raises an exception' do
      allow(RestClient).to receive(:get)
        .and_raise(RestClient::Exception.new(nil))
      expect { @record_sets.get_existing_records_for_recordset('A', 'RS_Name') }
        .to raise_error('no backtrace')
    end
  end

  describe '#get_existing_records_for_recordset' do
    it 'raises an exception with http_code 404' do
      allow(RestClient).to receive(:get)
        .and_raise(RestClient::Exception.new(nil, 404))
      expect { @record_sets.get_existing_records_for_recordset('A', 'RS_Name') }
        .to_not raise_error('no backtrace')
    end
  end

  describe '#set_records_on_record_set' do
    it 'sets records on recordset' do
      response = double
      allow(response).to receive(:code) { 200 }
      allow(RestClient).to receive(:put) { response }
      records = Array.new(['1.2.3.4', '1.2.3.5'])

      @record_sets.set_records_on_record_set('RS_Name', records, 'A', 300)
    end
  end

  describe '#set_records_on_record_set' do
    it 'raises an exception' do
      allow(RestClient).to receive(:put)
        .and_raise(RestClient::Exception.new(nil))
      records = Array.new(['1.2.3.4', '1.2.3.5'])
      expect { @record_sets.set_records_on_record_set('RS_Name', records, 'A', 300) }
        .to raise_error('no backtrace')
    end
  end

  describe '#remove_record_set' do
    it 'removes recordset' do
      response = double
      allow(response).to receive(:code) { 200 }
      allow(RestClient).to receive(:delete) { response }

      @record_sets.remove_record_set('Recordset_Name', 'A')
    end
  end

  describe '#remove_record_set' do
    it 'raises an exception' do
      allow(RestClient).to receive(:delete)
        .and_raise(RestClient::Exception.new(nil))
      expect { @record_sets.remove_record_set('Recordset_Name', 'A') }
        .to raise_error('no backtrace')
    end
  end

  describe '#remove_record_set' do
    it 'raises an exception with http code 404' do
      allow(RestClient).to receive(:delete)
        .and_raise(RestClient::Exception.new(nil, 404))
      expect { @record_sets.remove_record_set('Recordset_Name', 'A') }
        .to_not raise_error('no backtrace')
    end
  end
end
