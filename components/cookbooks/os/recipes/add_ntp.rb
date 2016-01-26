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
template "/etc/ntp.conf" do
  source "ntp.conf.erb"
  mode "0600"
   variables({
    :ntpservers => ntpservers
  })
  user "root"
  group "root"
end

service "ntpd" do
  action [ :enable, :start ]
end

ruby_block "Query NTP" do
  block do
    ntpstatus = `ntpq -p`
    Chef::Log.info("ntpq -p\n#{ntpstatus}")
  end
end
