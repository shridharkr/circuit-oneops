#
# Cookbook Name:: netscaler
# Recipe:: delete_lbvserver
#
# Copyright 2013 Walmart Labs


#include_recipe 'f5-bigip::provision_configsync'
require_relative "../libraries/resource_config_sync"

lbs = [] + node.loadbalancers + node.dcloadbalancers

lbs.each do |lb|

  sg_name = lb[:sg_name]
  f5_ltm_pool "#{sg_name}" do
    pool_name "#{sg_name}"
    f5 "#{node.f5_host}"
    action :delete
    notifies :run, "f5_config_sync[#{f5['hostname']}]", :delayed
  end

end
