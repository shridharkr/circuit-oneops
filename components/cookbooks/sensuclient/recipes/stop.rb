#
# Cookbook Name:: Sensuclient
# Recipe:: stop
#
#
# All rights reserved - Do Not Redistribute
service "sensu-client" do
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :stop
end
