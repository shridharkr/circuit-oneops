#
# Cookbook Name:: f5-bigip
# Recipe:: f5_delete_lbvserver
#
# Copyright 2013 Walmart Labs



lbs = node.loadbalancers + node.dcloadbalancers
lbs.each do |lb|

  lbvserver_name = lb['name']  
  f5_ltm_virtual_server "#{lbvserver_name}" do
    vs_name lbvserver_name
    f5  "#{node.f5_host}"
    action :delete
    notifies :run, "f5_config_sync[#{node.f5_host}]", :delayed
  end

end

include_recipe "f5-bigip::get_cert_name"

#Delete the SSL Profile
f5_ltm_sslprofiles  "#{node.cert_name}" do
  f5  "#{node.f5_host}"
  sslprofile_name "#{node.cert_name}"
  action :delete
  notifies :run, "f5_config_sync[#{f5['hostname']}]", :delayed
end

#Delete the Certificate and Key Objects from F5
f5_ltm_ssl "#{node.cert_name}" do
  f5  "#{node.f5_host}"
  mode  "MANAGEMENT_MODE_DEFAULT"
  ssl_id  "#{node.cert_name}"
  action :delete
  notifies :run, "f5_config_sync[#{f5['hostname']}]", :delayed
end
