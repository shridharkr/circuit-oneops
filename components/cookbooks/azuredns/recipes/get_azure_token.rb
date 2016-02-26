require 'rest_client'
require 'json'
require ::File.expand_path('../../libraries/token.rb', __FILE__)

cloud_name = node['workorder']['cloud']['ciName']
cloud = node['workorder']['services']['dns'][cloud_name]
dns_attributes = cloud['ciAttributes']
<<<<<<< HEAD

tenant_id = dns_attributes['tenant_id']
client_id = dns_attributes['client_id']
client_secret = dns_attributes['client_secret']

azure_token = AzureDns::Token.new(tenant_id, client_id, client_secret)
node.set['azure_rest_token'] = azure_token.generate_token
=======

tenant_id = dns_attributes['tenant_id']
client_id = dns_attributes['client_id']
client_secret = dns_attributes['client_secret']

<<<<<<< HEAD
token.run_action(:retrieve)
>>>>>>> 458d13a... Unit tests for azuredns:get_azure_token recipe. Recipe is refactored using LWRP and passes rubocop and foodcritic static code analysis. Integration tests verified via OneOps.
=======
azure_token = AzureDns::Token.new(tenant_id, client_id, client_secret)
node.set['azure_rest_token'] = azure_token.generate_token
>>>>>>> e50b8a8... DNS get_azure_token recipe: converted into class structure and write its unit test cases. Fixed Rubocop and Foodcritic offenses.
