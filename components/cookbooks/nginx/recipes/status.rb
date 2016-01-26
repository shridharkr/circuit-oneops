#
# Cookbook Name:: nginx
# Recipe:: status

service "nginx" do
  action :status
end
