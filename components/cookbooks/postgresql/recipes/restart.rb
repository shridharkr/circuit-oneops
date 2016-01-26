#
# Cookbook Name:: postgresql
# Recipe:: restart

service "postgresql-9.1" do
  action :restart
end
