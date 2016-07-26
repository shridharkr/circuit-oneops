#
# Cookbook Name:: Sensuclient
# Recipe:: restart
#
#
# All rights reserved - Do Not Redistribute

service "sensu-client" do
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :restart
end
