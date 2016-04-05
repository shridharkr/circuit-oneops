# Cookbook Name:: activemq
# Recipe:: repair
#

service "activemq" do
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :restart
end