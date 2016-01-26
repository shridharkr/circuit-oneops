# timezone
execute "rm -f /etc/localtime"
execute "ln -s /usr/share/zoneinfo/#{node.workorder.rfcCi.ciAttributes.timezone} /etc/localtime"

template "/etc/sysconfig/clock" do
  source "sysconfig_clock.erb"
  owner "root"
  group "root"
  mode 0644
  only_if { node.platform == "redhat" || node.platform == "centos" }
  not_if { ['docker'].index(provider) }
end

#Install NTP
if node[:workorder][:services].has_key?(:ntp)
 include_recipe "os::add_ntp"
else
  Chef::Log.info("Disabling NTP configuration since no cloud service found.")
  service_name = "ntpd"
  if node.platform == "ubuntu"
    service_name = "ntp"
  end
  
  service service_name do
    action [ :stop, :disable ]
  end
end
