cloud_name = node[:workorder][:cloud][:ciName]
services = node[:workorder][:services]
if services.nil?  || !services.has_key?(:ntp)
  Chef::Log.error('Please make sure your cloud has NTP service added.')
  puts "***FAULT:FATAL=Missing NTP cloud service"
  exit 1
end

ntp_service = services["ntp"][cloud_name]
ntpservers = JSON.parse(ntp_service[:ciAttributes][:servers])

Chef::Log.info("Configuring and enabling NTP")
if node['platform'] == 'windows'
  execute "w32tm /config /manualpeerlist:#{ntpservers.join(',')} /syncfromflags:MANUAL /reliable:yes" 
else
  template "/etc/ntp.conf" do
    source "ntp.conf.erb"
    mode "0600"
     variables({
      :ntpservers => ntpservers
    })
    user "root"
    group "root"
  end
end

service "ntpd" do
  case node['platform']
  when 'centos','redhat','fedora'
    service_name 'ntpd'
  when 'windows'
    service_name 'w32time'
  else
    service_name 'ntp'
  end
  action [ :enable, :start ]
end

if node['platform'] == 'windows'
  execute "w32tm /resync"
else
  ruby_block "Query NTP" do
    block do
      ntpstatus = `ntpq -p`
      Chef::Log.info("ntpq -p\n#{ntpstatus}")
    end
  end
end