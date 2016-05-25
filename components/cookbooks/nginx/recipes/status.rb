#
# Cookbook Name:: nginx
# Recipe:: status

execute 'systemctl status nginx' do
  user 'root'
  group 'root'
  ignore_failure true
end
