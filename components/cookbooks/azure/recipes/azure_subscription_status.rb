require 'azure_mgmt_resources'
require 'json'

::Chef::Recipe.send(:include, Azure::ARM::Resources)
::Chef::Recipe.send(:include, Azure::ARM::Resources::Models)

subscription_details = node[:workorder][:ci][:ciAttributes]

subscription_id = subscription_details[:subscription]
resource_group_name = subscription_details[:resource_group]
location = subscription_details[:location]
tenant_id = subscription_details['tenant_id']
client_id = subscription_details['client_id']
client_secret = subscription_details['client_secret']
express_route_enabled = subscription_details['express_route_enabled']
Chef::Log.info("tenant_id: #{tenant_id} client_id: #{client_id} client_secret: #{client_secret} subscription: #{subscription_id}")

# Create authentication objects
  token_provider = MsRestAzure::ApplicationTokenProvider.new(tenant_id,client_id,client_secret)
if token_provider != nil
    credentials = MsRest::TokenCredentials.new(token_provider)
end


if express_route_enabled == 'true'
  begin
  client = ResourceManagementClient.new(credentials)
  client.subscription_id = subscription_id
  # First, check if resource group is already created
  existance_promise = client.resource_groups.check_existence(resource_group_name)
  response = existance_promise.value!
  Chef::Log.info("response from azure:" +response.inspect)
  if(response.body == true)
    Chef::Log.info("Subscription details entered are verified")
  else
    puts "***FAULT:FATAL=Error verifying the subscription and credentials for #{subscription_id}"
    ex = Exception.new('no backtrace')
    ex.set_backtrace('')
    raise ex
  end
rescue  MsRestAzure::AzureOperationError =>e
      Chef::Log.error("Error verifying the subscription and credentials for #{subscription_id}")
      node.set["status_result"]="Error"
      if e.body != nil
        error_response = e.body["error"]
        Chef::Log.error("Error Response code:" +error_response["code"])
        Chef::Log.error("Error Response message:" +error_response["message"])
        puts "***FAULT:FATAL=#{error_response["message"]}"
        ex = Exception.new('no backtrace')
        ex.set_backtrace('')
        raise ex
      else
        Chef::Log.error("Error:"+e.inspect)
        puts "***FAULT:FATAL=Error verifying the subscription and credentials for #{subscription_id}"
        ex = Exception.new('no backtrace')
        ex.set_backtrace('')
        raise ex
      end

end
elsif express_route_enabled == 'false' || express_route_enabled == nil
  begin
  client = ResourceManagementClient.new(credentials)
  client.subscription_id = subscription_id
  # First, get list if resources associated with subdcription just to verify subscription and credentials
  promise = client.resource_groups.list()
  response = promise.value!
  Chef::Log.debug("response from azure:" +response.inspect)
  if(response.body != nil)
    Chef::Log.info("Subscription details entered are verified")
  else
    raise e
  end
rescue  MsRestAzure::AzureOperationError =>e
      Chef::Log.error("Error verifying the subscription and credentials for #{subscription_id}")
      node.set["status_result"]="Error"
      if e.body != nil
        error_response = e.body["error"]
        Chef::Log.error("Error Response code:" +error_response["code"])
        Chef::Log.error("Error Response message:" +error_response["message"])
        puts "***FAULT:FATAL=#{error_response["message"]}"
        ex = Exception.new('no backtrace')
        ex.set_backtrace('')
        raise ex
      else
        Chef::Log.error("Error:"+e.inspect)
        puts "***FAULT:FATAL=Error verifying the subscription and credentials for #{subscription_id}"
        ex = Exception.new('no backtrace')
        ex.set_backtrace('')
        raise ex
      end
  end
end
