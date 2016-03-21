# Cookbook Name:: activemq
# Recipe:: stop
#

service "activemq" do
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :stop
end
