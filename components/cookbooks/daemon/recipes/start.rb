#
# Cookbook Name:: daemon
# Recipe:: start
#
attrs = node.workorder.ci.ciAttributes
service_name = attrs[:service_name]
pat = attrs[:pattern] || ''

if pat.empty?
  service "#{service_name}" do
    action :start
  end

else
  service "#{service_name}" do
    pattern "#{pat}"
    action :start
  end
end