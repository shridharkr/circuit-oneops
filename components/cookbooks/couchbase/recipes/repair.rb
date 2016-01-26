#
# Cookbook Name:: couchbase
# Recipe:: repair
#

# Using start instead of restart
# start does not have a negative impact if the service is already running
service "couchbase-server" do
  action :start
end
