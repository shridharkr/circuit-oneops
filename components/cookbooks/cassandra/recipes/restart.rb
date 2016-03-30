#
# Cookbook Name:: cassandra
# Recipe:: restart
#
service "cassandra" do
  supports :status => true, :start => true, :stop => true, :restart => true
  action :restart
end
localIp = node[:ipaddress]
ruby_block "is_port_open" do
   Chef::Resource::RubyBlock.send(:include, Cassandra::Util)
   block do
    port_open(localIp)
   end
end