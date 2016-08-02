require 'uri'
require 'openssl'
require 'base64'
require 'net/https'
require 'net/http'
require 'rest-client'
require 'json'
require 'crack'

# TODO: move all of this to a helper class to remove code duplication

Chef::Log.info('MADE IT TO PANOS UPDATE RECIPE')

service = PanosUtils.get_service_info(node)

addresses = PanosUtils.get_computes(node)

# cloud_name = node[:workorder][:cloud][:ciName]
# Chef::Log.info("Cloud Name: #{cloud_name}")
# 
# # get the service information
# if node[:workorder][:services].has_key?(:firewall)
  # Chef::Log.info("FW SERVICE IS: #{node[:workorder][:services][:firewall]}")
  # fw_attributes =
    # node[:workorder][:services][:firewall][cloud_name][:ciAttributes]
  # url_endpoint = fw_attributes[:endpoint]
  # username = fw_attributes[:username]
  # password = fw_attributes[:password]
# end
# 
# # get all the computes we are dealing with 
# if !node[:workorder][:payLoad].has_key?(:RequiresComputes)
  # msg = 'RequiresComputes does not exist for compute and firewall'
  # puts "***FAULT:FATAL=#{msg}"
  # e = Exception.new(msg)
  # raise e
# else
  # # for the Computes, need to add to an array and submit those to be created/updated/deleted in the firewall
  # addresses = Hash.new { |h,k| h[k] = Array.new }
  # computes = node[:workorder][:payLoad][:RequiresComputes].select { |d| d[:ciClassName] =~ /Compute/ }
  # computes.each do |compute|
    # instance_name = compute[:ciAttributes][:instance_name]
    # ip_address = compute[:ciAttributes][:private_ip]
    # addresses['entries'] << {'name' => instance_name, 'ip_address' => ip_address}
  # end
# end

Chef::Log.info("ADDRESSES are: #{addresses}")

# get the tag name
# nsPathParts = node[:workorder][:rfcCi][:nsPath].split('/')
# org_name = nsPathParts[1]
# assembly_name = nsPathParts[2]
# environment_name = nsPathParts[3]
# platform_ciid = node.workorder.box.ciId.to_s
# 
# tag = org_name[0..15] + '-' + assembly_name[0..15] + '-' + platform_ciid + '-' + environment_name[0..15]

tag = PanosUtils.get_tag_name(node)

# update the firewall
# could be scaling up/down or replacing a VM (which would be updating an existing address)
panos_firewall 'Update Panos Firewall' do
  url_endpoint service[:url_endpoint]
  username service[:username]
  password service[:password]
  tag tag
  addresses addresses
  action :update
end
