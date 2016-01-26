#
# Cookbook Name:: daemon
# Recipe:: status
#
service_name = node.workorder.ci.ciAttributes[:service_name]

execute "service #{service_name} status"
