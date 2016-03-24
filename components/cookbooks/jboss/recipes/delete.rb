#
# Cookbook Name:: jboss
# Recipe:: delete
#

service "jboss" do
  action [:disable, :stop]
end
