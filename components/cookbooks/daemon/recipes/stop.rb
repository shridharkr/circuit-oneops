# Cookbook Name:: daemon
# Recipe:: stop
#
attrs = node.workorder.ci.ciAttributes
service_name = attrs[:service_name]
pat = attrs[:pattern] || ''

if pat.empty?
  service "#{service_name}" do
    action :stop
  end
  
else 
  service "#{service_name}" do
    pattern "#{pat}"
    action :restart
  end
end