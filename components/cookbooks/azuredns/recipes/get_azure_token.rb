
require 'rest_client'
require 'json'

cloud_name = node['workorder']['cloud']['ciName']
dns_attributes = node['workorder']['services']['dns'][cloud_name]['ciAttributes']

#  Establish connection and get a security token
login_url = 'https://login.windows.net/' + dns_attributes['tenant_id'] + '/oauth2/token'

if ENV.has_key?('http_proxy')
  Chef::Log.info("azuredns:get_azure_token.rb - Setting proxy on RestClient for calls to Azure: #{ENV['http_proxy']}")
  RestClient.proxy = ENV['http_proxy']
end

begin
  token_response = RestClient.post(
      login_url,
      'client_id' => dns_attributes['client_id'],
      'client_secret' => dns_attributes['client_secret'],
      'grant_type' => 'client_credentials',
      'resource' => 'https://management.azure.com/'
  )
  token = 'Bearer ' + JSON.parse(token_response)['access_token']
  node.set['azure_rest_token'] = token
rescue Exception => e
  msg = "Exception trying to retrieve the token."
  puts "***FAULT:FATAL=#{msg}"
  Chef::Log.error("azuredns::get_azure_token.rb - Exception is: #{e.message}")
  e = Exception.new('no backtrace')
  e.set_backtrace('')
  raise e
end

# use a rest call to get the NS records from Azure instead of dig
if node['azure_rest_token'].nil? || node['azure_rest_token'].size == 0
  msg = 'azuredns:get_azure_token.rb - No Token.  Without it I can not communicate with Azure.  Raise an Exception!'
  puts "***FAULT:FATAL=#{msg}"
  Chef::Log.error(msg)
  e = Exception.new('no backtrace')
  e.set_backtrace('')
  raise e
end
