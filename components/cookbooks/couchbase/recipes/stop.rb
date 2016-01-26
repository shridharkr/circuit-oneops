#
# Cookbook Name:: couchbase
# Recipe:: stop

service "couchbase-server" do
  action :stop
end
