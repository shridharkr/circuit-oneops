#
# Cookbook Name:: couchbase
# Recipe:: restart
#
service "couchbase-server" do
  action :restart
end
