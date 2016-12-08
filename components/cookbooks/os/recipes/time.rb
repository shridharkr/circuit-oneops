#set timezone
timezone = node.workorder.rfcCi.ciAttributes.timezone
if node['platform'] == "windows"
  execute "tzutil.exe /s #{timezone}"
else
  execute "rm -f /etc/localtime"
  execute "ln -s /usr/share/zoneinfo/#{timezone} /etc/localtime"
end


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

  service_name =  case node.platform
    when 'windows' 
      'w32time'
    when 'ubuntu'
      'ntp'
    else 
      'ntpd'
  end
  
  service service_name do
    action [ :stop, :disable ]
  end
end
