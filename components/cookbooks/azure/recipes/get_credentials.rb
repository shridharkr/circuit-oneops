require 'azure_mgmt_compute'


## NOTE: This recipe is tobe deleted. It is replaced by
## AzureCommon::AzureUtils.get_credentials() in azure/libraries/azure_utils.rb

cloud_name = node['workorder']['cloud']['ciName']
tenant_id = node['workorder']['services']['compute'][cloud_name]['ciAttributes']['tenant_id']
client_id = node['workorder']['services']['compute'][cloud_name]['ciAttributes']['client_id']
client_secret = node['workorder']['services']['compute'][cloud_name]['ciAttributes']['client_secret']
subscription = node['workorder']['services']['compute'][cloud_name]['ciAttributes']['subscription']

Chef::Log.info("tenant_id: #{tenant_id} client_id: #{client_id} client_secret: #{client_secret} subscription: #{subscription}")
begin
  # Create authentication objects
  token_provider = MsRestAzure::ApplicationTokenProvider.new(tenant_id,client_id,client_secret)
  if token_provider != nil
    credentials = MsRest::TokenCredentials.new(token_provider)
    node.set['azureCredentials'] = credentials
  else
    raise e
  end
rescue  MsRestAzure::AzureOperationError =>e
  Chef::Log.error("Error acquiring a token from azure")
  e = Exception.new("no backtrace")
  e.set_backtrace("no backtrace")
  raise e
end
