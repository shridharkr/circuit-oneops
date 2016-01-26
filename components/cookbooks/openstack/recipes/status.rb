#
# openstack::status - gets quota info
# 

require 'fog'

token = node[:workorder][:ci][:ciAttributes]

conn = Fog::Compute.new({
  :provider => 'OpenStack',
  :openstack_api_key => token[:password],
  :openstack_username => token[:username],
  :openstack_tenant => token[:tenant],
  :openstack_auth_url => token[:endpoint]
})



limits_all = conn.get_limits.body["limits"]

limits = limits_all["absolute"]
Chef::Log.info("limits: "+limits.inspect)

puts "***RESULT:max_instances=#{limits['maxTotalInstances']}"
puts "***RESULT:max_cores=#{limits['maxTotalCores']}"
puts "***RESULT:max_ram=#{limits['maxTotalRAMSize']}"
puts "***RESULT:max_keypairs=#{limits['maxTotalKeypairs']}"
puts "***RESULT:max_secgroups=#{limits['maxSecurityGroups']}"
