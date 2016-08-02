require 'uri'
require 'openssl'
require 'base64'
require 'net/https'
require 'net/http'
require 'rest-client'
require 'json'
require 'crack'

Chef::Log.info('MADE IT TO PANOS DEFAULT RECIPE')

Chef::Log.info("NEW IP ADDRESS IS: #{node[:ip]}")

# add logic to throw an error if IP is not found.

cloud_name = node[:workorder][:cloud][:ciName]
Chef::Log.info("Cloud Name: #{cloud_name}")

if node[:workorder][:services].has_key?(:firewall)
  Chef::Log.info("FW SERVICE IS: #{node[:workorder][:services][:firewall]}")
  fw_attributes =
    node[:workorder][:services][:firewall][cloud_name][:ciAttributes]
  url_endpoint = fw_attributes[:endpoint]
  username = fw_attributes[:username]
  password = fw_attributes[:password]
end

name = node[:workorder][:rfcCi][:ciAttributes][:instance_name]

# update the firewall with a new ip address
panos_firewall 'Panos Firewall' do
  url_endpoint url_endpoint
  username username
  password password
  address_name name
  new_ip node[:ip]
  action :update
end
