#
# Cookbook Name:: cassandra
# Recipe:: start
#
service "cassandra" do
  action :start
end
localIp = node[:ipaddress]
ruby_block "is_port_open" do
   Chef::Resource::RubyBlock.send(:include, Cassandra::Util)
   block do
    port_open(localIp)
   end
end
