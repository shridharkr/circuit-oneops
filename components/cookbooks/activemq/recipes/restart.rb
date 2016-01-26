#
# Cookbook Name:: activemq
# Recipe:: restart
#
service "activemq" do
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :restart
end
