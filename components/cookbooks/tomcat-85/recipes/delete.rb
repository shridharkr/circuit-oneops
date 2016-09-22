
service "tomcat" do
  only_if { ::File.exists?('/etc/init.d/tomcat') }
  service_name "tomcat"
  action [:stop, :disable]
end

directory "#{node['tomcat']['tomcat_config_dir']}" do
   recursive true
   action :delete
end
