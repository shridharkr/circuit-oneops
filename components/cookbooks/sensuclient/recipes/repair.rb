#
# Cookbook Name:: Sensuclient
# Recipe:: repair
#
#
# All rights reserved - Do Not Redistribute
service "sensu-client" do
  action :restart
end
