# rubocop:disable MethodLength
# rubocop:disable LineLength
require_relative '../../../../constants'
require 'chef'
module AzureDns
  # DNS Zone Class
  class Zone
    def initialize(dns_attributes, token, platform_resource_group)
      @subscription = dns_attributes['subscription']
      @dns_resource_group = platform_resource_group
      @zone = dns_attributes['zone']
      @token = token
    end

    def check_for_zone
      # construct the URL to get the records from the dns zone
      resource_url = "#{AZURE_RESOURCE}subscriptions/#{@subscription}/resourceGroups/#{@dns_resource_group}/providers/Microsoft.Network/dnsZones/#{@zone}?api-version=2015-05-04-preview"
      begin
        RestClient.get(
          resource_url,
          accept: 'application/json',
          content_type: 'application/json',
          authorization: @token
        )
        true
      rescue RestClient::Exception => e
        if e.http_code == 404
          false
        else
          Chef::Log.error("AzureDns:Zone - Excpetion is: #{e.message}")
          e = Exception.new('no backtrace')
          e.set_backtrace('')
          raise e
        end
      end
    end

    def create
      # construct the URL to get the records from the dns zone
      resource_url = "#{AZURE_RESOURCE}subscriptions/#{@subscription}/resourceGroups/#{@dns_resource_group}/providers/Microsoft.Network/dnsZones/#{@zone}?api-version=2015-05-04-preview"
      body = {
        location: 'global',
        tags: {},
        properties: {} }
      begin
        RestClient.put(
          resource_url,
          body.to_json,
          accept: 'application/json',
          content_type: 'application/json',
          authorization: @token)
      rescue => e
        Chef::Log.error("AzureDns:Zone - Excpetion is: #{e.message}")
        e = Exception.new('no backtrace')
        e.set_backtrace('')
        raise e
      end
    end
  end
end
