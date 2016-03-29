# Cookbook Name:: activemq
# Recipe:: start
#

service "activemq" do
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :start
end
